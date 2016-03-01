# encoding: utf-8
When /^I debug the app shell$/ do
  STDOUT.puts 'Opening shell in a separate window.'
  if RUBY_PLATFORM =~ /darwin/
    app_shell('open -a Terminal .')
  else
    raise "Don't know how to open an app shell for #{RUBY_PLATFORM}; please contribute your knowledge to #{__FILE__}"
  end
  STDOUT.puts 'Press Enter to continue Cucumber execution...'
  STDOUT.flush
  STDIN.readline
end
