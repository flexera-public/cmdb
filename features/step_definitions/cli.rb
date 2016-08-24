# encoding: utf-8
require 'cucumber/rspec/doubles'

# Run the shim as a subprocess
Given /^a shim with parameters "(.*)" running webrick$/ do |options|
  step(%(I run cmdb with "#{options} shim -- rackup -s webrick -p #{app_port}"))

  # Wait for app to start up before we return from this step
  step(%(the output should include "I am up and running")) unless @shim_die_on_startup
end

# Populate the app's env with some parameters
Given /^\$([A-Z0-9_]+) is "(.*)"$/ do |key, value|
  app_env[key] = value
end

# Run cmdb as a subprocess with the specified options
When(/^I run cmdb with "(.*)"$/) do |options|
  script = File.expand_path('../../../exe/cmdb', __FILE__)

  sfl = sources.map { |s| "--source=#{s}" }.join ' '
  cmd = "bundle exec #{script} #{sfl} #{options}"

  Cucumber.logger.debug("bash> #{cmd}\n")
  Bundler.with_clean_env do
    ENV['DIE_DIE_DIE'] = 'yes please' if @shim_die_on_startup
    app_env.each_pair { |k, v| ENV[k] = v }

    Dir.chdir(app_root) do
      @shim_command = Backticks.new(cmd)
    end
  end
end

Then(/^"(.*)" should look like:$/) do |filename, content|
  filename = File.join(app_root, filename)
  file = File.read(filename)

  parsed_file = YAML.load(file)
  parsed_content = YAML.load(content)

  expect(parsed_file).to eq(parsed_content)
end

Then /^the command should (succeed|fail)$/ do |pass_fail|
  # wait for cmdb to exit if it was run as a subprocess
  if @shim_command && @shim_command.status.nil?
    @shim_command.join
    @shim_exitstatus = @shim_command.status.exitstatus
  end

  if pass_fail == 'succeed'
    expect(@shim_exitstatus).to eq(0)
  else
    expect(@shim_exitstatus).not_to eq(0)
  end
end

Then /^the exitstatus should be ([0-9]+)$/ do |status|
  expect(@shim_command.pid).to be_a(Integer)
  @shim_command.join
  @shim_exitstatus = @shim_command.status.exitstatus

  expect(@shim_exitstatus).to eq(Integer(status))
end

And /^the output should (not )?include "(.*)"$/ do |negatory, message|
  if @shim_command
    # Shim was run as a subprocess; look at its stdout
    @shim_command.join(3)
    @shim_output = @shim_command.captured_output
  else
    # Shim was run in-process; make sure test rigging initialized captured
    # its output
    expect(@shim_output).not_to be_nil
    @shim_output = @shim_output.string if @shim_output.is_a?(StringIO)
  end

  if negatory
    expect(@shim_output).not_to include(message)
  else
    expect(@shim_output).to include(message)
  end
end

And /^the output should have keys: (.*)$/ do |kvs|
  if @shim_command
    # Shim was run as a subprocess; look at its stdout
    @shim_command.join(3)
    @shim_output = @shim_command.captured_output
  else
    # Shim was run in-process; make sure test rigging initialized captured
    # its output
    expect(@shim_output).not_to be_nil
    @shim_output = @shim_output.string if @shim_output.is_a?(StringIO)
  end

  kvs = kvs.split(/;/)
  kvs = kvs.inject({}) { |h, kv| p = kv.split('='); h[p.first] = p.last; h }

  mismatched = []
  kvs.each do |k, v|
    mismatched << k unless @shim_output.include?(k + '=' + v)
  end
  expect(mismatched).to be_empty
end
