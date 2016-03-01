# encoding: utf-8
Given /^RACK_ENV is unset$/ do |_value|
  app_env['RACK_ENV'] = nil
end

Given /^RACK_ENV is "(.*)"$/ do |value|
  app_env['RACK_ENV'] = value
end
