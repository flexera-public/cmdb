# encoding: utf-8

require 'docker/compose'

# Create a source with the specified URL. Perform docker-compose mapping for
# sources that
Given /^a source "([^"]+)"$/ do |uri|
  uri = URI.parse(uri)
  case uri.scheme
  when 'consul'
    s = Docker::Compose::Session.new(dir: File.expand_path('../../..', __FILE__))
    m = Docker::Compose::Mapper.new(s)
    uri.host = 'consul' # rude! user's hostname/port do not matter...
    uri.port = 8500
    uri = m.map(uri.to_s)
  end

  sources << CMDB::Source.create(uri)
end

# Given an "absolute" path name, write a file. The path is actually appended
# to the fake root to avoid trashing the host filesystem; the "given a source"
# step transforms its file URLs accordingly.
Given /^a file source "([^"]+)" containing:$/ do |path, content|
  filename = fake_path(path)
  FileUtils.mkdir_p(File.dirname(filename))
  File.open(filename, 'w') { |f| f.write(content) }
  step(%Q{a source "file://#{filename}"})
end
