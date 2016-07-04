# encoding: utf-8
describe CMDB::Source::File do
  let(:data) { { 'foo.bar' => 'foobar', 'baz' => [1, 2, 3], 'quux' => true } }
  let(:source_prefix) { 'common' }
  let(:source_key_env) { { 'FOO_BAR' => 'foobar', 'BAZ' => '[1,2,3]', 'QUUX' => 'true' } }
  let(:source_key_dotted) { { 'common.foo.bar' => 'foobar', 'common.baz' => [1, 2, 3], 'common.quux' => true } }
  let(:data_types) { [Array, TrueClass] }

  let(:raw_data) { JSON.dump(data) }
  let(:data_file) { Tempfile.new(['cmdb--rspec', '.json']) }

  before do
    data_file.puts(raw_data)
    data_file.flush
  end

  after do
    data_file.close
    data_file.unlink
  end

  subject { CMDB::Source::File.new(data_file.path, nil, 'common') }

  it_behaves_like 'a source'
end
