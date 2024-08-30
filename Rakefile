# encoding: utf-8

require 'rubygems'
require 'bundler/setup'
require 'bundler/gem_tasks'

require 'cucumber/rake/task'
desc 'Run functional tests'
Cucumber::Rake::Task.new do |t|
  t.cucumber_opts = %w(--color --format pretty)
end

require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)

require 'coveralls/rake/task'
Coveralls::RakeTask.new

task default: [:spec, :cucumber, 'coveralls:push']


require 'docker/compose'
desc 'Create Consul source using Docker Compose and invoke cmdb shell'
task :sandbox do
  compose = Docker::Compose::Session.new
  compose.up 'consul', detached:true
  mapper = Docker::Compose::Mapper.new(compose)
  source1 = mapper.map('consul://consul:8500/sandbox/apples')
  source2 = mapper.map('consul://consul:8500/sandbox/oranges')
  exec "bin/shell --source=#{source1} --source=#{source2}"
end
