# encoding: utf-8

# Create a source with the specified URL.
Given /^a source "([^"]+)"$/ do |uri|
  sources << URI.parse(uri)
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
