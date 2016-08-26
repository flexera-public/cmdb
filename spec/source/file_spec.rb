# encoding: utf-8
describe CMDB::Source::File do
  let(:source_prefix) { 'common' }
  let(:source_data) { { 'common.foo.bar' => 'foobar', 'common.baz' => [1, 2, 3], 'common.quux' => true } }

  let(:raw_data) do
    hh = source_data.inject({}) { |h, kv| h[kv[0].sub('common.', '')] = kv[1]; h }
    JSON.dump(hh)
  end

  let(:data_file) { Tempfile.new(['cmdb--rspec', '.json']) }

  before do
    data_file.puts(raw_data)
    data_file.flush
  end

  after do
    data_file.close
    data_file.unlink
  end

  subject { CMDB::Source::File.new(data_file.path, 'common') }

  it_behaves_like 'a source'
end
