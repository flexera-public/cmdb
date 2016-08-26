# encoding: utf-8

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

Then(/^the code should raise CMDB::BadData$/) do
  expect do
    cmdb.get('bogus')
  end.to raise_error(CMDB::BadData)
end

Then(/^the code should raise CMDB::BadValue$/) do
  expect do
    cmdb.get('bogus')
  end.to raise_error(CMDB::BadValue)
end
