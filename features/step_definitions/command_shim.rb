require 'cucumber/rspec/doubles'

# Run the shim as a subprocess
Given /^cmdb shim with argv "(.*)" running webrick$/ do |options|
  step(%Q{I run cmdb shim with argv "#{options} -- rackup -s webrick -p #{app_port}"})

  # Wait for app to start up before we return from this step
  step(%Q{the output should include "I am up and running"}) unless @command_die
end

# Run the shim as a subprocess with the specified options
When(/^I run cmdb shim with argv "(.*)"$/) do |options|
  keydirs = "--keys #{fake_var_lib} #{fake_home}/.cmdb"
  script = File.expand_path('../../../exe/cmdb', __FILE__)
  cmd = "bundle exec #{script} shim #{keydirs} #{options}"

  Cucumber.logger.debug("bash> #{cmd}\n")
  Bundler.with_clean_env do
    ENV['DIE_DIE_DIE'] = 'yes please' if @command_die
    app_env.each_pair { |k, v| ENV[k] = v }

    Dir.chdir(app_root) do
      @command = Backticks.new(cmd)
    end
  end
end
