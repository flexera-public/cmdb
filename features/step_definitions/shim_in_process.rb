# encoding: utf-8
# Construct a shim in process; do not actually run it.
When /^I run Commands::Shim with(out)? "user:?(.*)"$/ do |negatory, user|
  command = ['ls']
  @shim_in_process_output = StringIO.new
  @shim_logger = Logger.new(@shim_in_process_output)
  @interface = CMDB::Interface.new

  opts = {rewrite:false, pretend:false, env:false, user:nil}
  opts[:user] = user unless negatory

  @shim = CMDB::Commands::Shim.new(@interface, command, **opts)

  CMDB.log = @shim_logger
end

# Run the shim in process; stub syscalls to verify correct behavior without
# doing anything nasty.
Then /^the command should (not )?setuid( to "(.*)")?$/ do |negatory, _, user|
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
    @shim_output = @shim_in_process_output.string
    @shim_exitstatus = 0
  rescue SystemExit => e
    @shim_exitstatus = e.status
  end
end
