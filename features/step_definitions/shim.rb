# Construct a command object in process to test setuid, which can't easily
# be tested in a subprocess.
When /^I run the shim with(out)? "--user=?(.*)"$/ do |negatory, user|
  command = ['ls']
  @shim_output = StringIO.new
  @shim_logger = Logger.new(@shim_output)

  if negatory
    @shim = CMDB::Commands::Shim.new(command, :quiet => true)
  else
    @shim = CMDB::Commands::Shim.new(command, :quiet => true, :user => user)
  end

  CMDB.log = @shim_logger
end

# Run the shim in-process; stub syscalls to verify correct behavior without
# doing anything nasty.
Then /^the shim should (not )?setuid( to "(.*)")?$/ do |negatory, _, user|
  command = ['ls']
  begin
    allow(@shim).to receive(:exec).with(*command)
    allow(CMDB::Commands::Shim).to receive(:drop_privileges)

    if negatory
      expect(CMDB::Commands::Shim).not_to receive(:drop_privileges)
    else
      expect(CMDB::Commands::Shim).to receive(:drop_privileges).with(user)
    end

    @shim.run
    @output = @shim_output.string
    @exitstatus = 0
  rescue SystemExit => e
    @exitstatus = e.status
  end
end
