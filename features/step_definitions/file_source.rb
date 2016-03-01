# encoding: utf-8
Given /^an? (etc|homedir|working-dir) file "([a-z0-9_.]+)" containing:$/ do |loc, filename, content|
  dir = case loc
        when 'etc' then File.join(fake_var_lib)
        when 'homedir' then File.join(fake_home, '.cmdb')
        when 'working-dir' then File.join(app_root, '.cmdb')
        else raise 'Cucumber step needs to be updated'
  end

  filename = File.join(dir, filename)
  FileUtils.mkdir_p(File.dirname(filename))
  File.open(filename, 'w') { |f| f.write(content) }
end
