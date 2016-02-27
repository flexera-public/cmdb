begin
  require 'pry'
rescue LoadError
  # no-op; debug gems are omitted from CI
end

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'rspec'
require 'cmdb'

RSpec.configure do |config|
  
end
