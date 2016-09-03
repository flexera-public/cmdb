# encoding: utf-8

Then /^<<([^>]*)>> should be nil$/ do |key|
  cmdb.get(key).should be_nil
end

Then /^<<([^>]*)>> should be "(.*)"$/ do |key, value|
  expect(cmdb.get(key)).to eq(value)
end

Then /^<<([^>]*)>> should be ([0-9]+)$/ do |key, value|
  expect(cmdb.get(key)).to be_an Integer
  expect(cmdb.get(key)).to eq(value.to_i)
end

Then /^<<([^>]*)>> should be true$/ do |key|
  expect(cmdb.get(key)).to eq(true)
end

Then /^<<([^>]*)>> should be false$/ do |key|
  expect(cmdb.get(key)).to eq(false)
end

Then /^<<([^>]*)>> should be (\[.*\])$/ do |key, array|
  array = eval(array)
  expect(cmdb.get(key)).to eq(array)
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
