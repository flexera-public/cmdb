# encoding: utf-8
require 'rubygems'
require 'bundler/setup'
require 'sinatra'

Signal.trap('HUP') do
  puts 'I got a SIGHUP'
end

Signal.trap('USR2') do
  puts 'I got a SIGUSR2'
end

app_dir = File.expand_path('../app', __FILE__)

Dir.glob(File.join(app_dir, '**', '*')).each do |f|
  require f
end

set :environment, :development
set :run, false
set :raise_errors, true

if ENV['DIE_DIE_DIE']
  puts "I am dying as requested by ENV['DIE_DIE_DIE']"
  exit(42)
else
  puts 'I am up and running'
  run Sinatra::Application
end
