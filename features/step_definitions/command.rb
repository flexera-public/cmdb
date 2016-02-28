require 'cucumber/rspec/doubles'

Then /^the command should (succeed|fail)$/ do |pass_fail|
  @command.should_not be_nil

  # wait for shim to exit if it was run as a subprocess
  if @command && @command.status.nil?
    @command.join
    @exitstatus = @command.status.exitstatus
  end

  if pass_fail == 'succeed'
    @exitstatus.should eq(0)
  else
    @exitstatus.should_not eq(0)
  end
end

Then /^the exitstatus should be ([0-9]+)$/ do |status|
  @command.should_not be_nil
  @command.pid.should be_a(Integer)
  @command.join
  @exitstatus = @command.status.exitstatus

  @exitstatus.should eq(Integer(status))
end
