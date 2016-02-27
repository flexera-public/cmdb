Given /^a trivial app$/ do
  FileUtils.cp_r(Dir[File.join(fixtures_root, '*')], app_root)

  File.open(app_path('Gemfile'), 'a') do |f|
    f.puts "gem 'cmdb', :path=>'#{File.expand_path('../../..', __FILE__)}'"
  end

  app_shell('bundle check || bundle install')
end

# Ask the fixture app to simulate failure on startup
Given /^a startup bug in the app$/ do
  @shim_die_on_startup = true
end

# Create a file under the app (e.g. that contains replacement tokens).
# Create parent dir(s) for the file if they don't already exist.
Given(/^an app file "(.*)" containing:$/) do |filename, content|
  filename = File.join(app_root, filename)
  FileUtils.mkdir_p(File.dirname(filename))
  File.open(filename, 'w') { |f| f.write(content) }
end

# Change mtime for an app file
When /^I touch "(.*)"$/ do |path|
  FileUtils.touch(app_path(path))
end

# Create or replace an app file
When /I create "(.*)" with content:$/ do |path, content|
  File.open(app_path(path), 'w') do |f|
    f.puts content
  end
end
