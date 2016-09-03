# encoding: utf-8

begin
  require 'pry'
rescue LoadError
  # no-op; debug gems are omitted from CI
  puts 'No pry'
end

require 'rspec'
require 'webmock/rspec'

RSpec.configure do |config|
  config.before(:each) do
    WebMock.reset!
  end
end
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'coveralls'
Coveralls.wear!

require 'cmdb'

require_relative 'source/shared_examples'
