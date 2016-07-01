# encoding: utf-8
require 'tmpdir'

require 'backticks'

begin
  require 'pry'
rescue LoadError
  # no-op; debug gems are omitted from CI
end

STDOUT.sync = STDERR.sync = true

lib_dir = File.expand_path('../../../lib', __FILE__)
$LOAD_PATH << lib_dir unless $LOAD_PATH.include?(lib_dir)

require 'cmdb'

module FakeAppHelper
  def fake_root
    @fake_root ||= Dir.mktmpdir('cucumber--cmdb')
  end

  def fixtures_root
    File.expand_path('../../../fixtures', __FILE__)
  end

  def app_root
    fake_path('client_app')
  end

  def app_port
    @app_port ||= (3000 + rand(20_000))
  end

  def app_env
    @app_env ||= {}
  end

  def fake_var_lib
    fake_path('var', 'lib', 'cmdb')
  end

  def fake_home
    fake_path('home')
  end

  def fake_path(*args)
    path = fake_root
    until args.empty?
      item = args.shift
      path = File.join(path, item)
    end
    path
  end

  def app_path(*args)
    path = app_root
    until args.empty?
      item = args.shift
      path = File.join(path, item)
    end
    path
  end

  # Run a shell command in app_dir, e.g. a rake task
  def app_shell(cmd, options = {})
    ignore_errors = options[:ignore_errors] || false

    Dir.chdir(app_root) do
      Cucumber.logger.debug("bash> #{cmd}\n")
      Bundler.with_clean_env do
        runner = Backticks::Runner.new(interactive: true)
        command = runner.command(cmd)
        command.join
        $CHILD_STATUS.success?.should == true unless ignore_errors
        command.captured_output
      end
    end
  end
end

module ScenarioState
  def cmdb
    @cmdb ||= CMDB::Interface.new
  end
end

module CucumberWorld
  include FakeAppHelper
  include ScenarioState

  # @return [String] the filename and line of the current scenario
  attr_reader :scenario_location
end

Before do |scenario|
  @scenario_location = scenario.location

  @original_env = {}
  ENV.each_pair { |k, v| @original_env[k] = v }

  ENV['RACK_ENV'] = nil
  FileUtils.mkdir_p(app_path('config'))

  # ensure that shim et al see PWD as app root
  @old_pwd = Dir.pwd
  Dir.chdir(app_root)
end
# The Cucumber world
World(CucumberWorld)

# Cleanup to perform after each test case
After do |scenario|
  Dir.chdir(@old_pwd)

  ENV.keys.each { |k| ENV[k] = nil }
  @original_env.each_pair { |k, v| ENV[k] = v }

  FileUtils.rm_rf(app_path('config'))

  # Make sure we shut down the shim process (and hopefully any child processes)
  if @shim_command
    Cucumber.logger.debug("waiting for shim (pid #{@shim_command.pid}) to die\n")

    begin
      Process.kill('QUIT', @shim_command.pid)
      @shim_command.join
    rescue
      Cucumber.logger.debug("shim is already dead (#{$ERROR_INFO})\n")
    end

    if scenario.failed?
      Cucumber.logger.debug("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n")
      text = @shim_command.captured_output + @shim_command.captured_error
      text.split(/[\n\r]+/).each do |line|
        Cucumber.logger.debug("!!! #{line}\n")
      end
      Cucumber.logger.debug("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n")
    end
  end
end
