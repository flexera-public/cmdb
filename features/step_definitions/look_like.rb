Then(/^"(.*\.[Yy][Aa]?[Mm][Ll])" should look like:$/) do |filename, content|
  filename = File.join(app_root, filename)
  file = File.read(filename)

  parsed_file = YAML.load(file)
  parsed_content = YAML.load(content)

  parsed_file.should == parsed_content
end
