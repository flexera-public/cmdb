Then /^<<([^>]*)>> should be nil$/ do |key|
  cmdb.get(key).should be_nil
end

Then /^<<([^>]*)>> should be "(.*)"$/ do |key, value|
  cmdb.get(key).should == value
end

Then /^<<([^>]*)>> should be ([0-9]+)$/ do |key, value|
  cmdb.get(key).should be_an Integer
  cmdb.get(key).should == value.to_i
end

Then /^<<([^>]*)>> should be true$/ do |key|
  cmdb.get(key).should == true
end

Then /^<<([^>]*)>> should be false$/ do |key|
  cmdb.get(key).should == false
end

Then /^<<([^>]*)>> should be (\[.*\])$/ do |key, array|
  array = eval(array)
  cmdb.get(key).should == array
end

Then /^the code should raise ([A-Z0-9]*)$/ do |classname|
  klass = eval(classname)
  expect {
    cmdb.get('bogus')
  }.to raise_error(klass)
end
