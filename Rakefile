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

task default: [:spec, :cucumber]

desc 'Invoke cmdb shell in a Docker sandbox with toy consul server'
task :sandbox do
  exec 'docker-compose run cmdb'
end
