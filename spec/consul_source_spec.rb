# encoding: utf-8
describe CMDB::ConsulSource do
  let(:data) { { 'foo.bar' => 'foobar', 'baz' => [1, 2, 3], 'quux' => true } }
  let(:source_prefix) { 'common' }
  let(:source_key_env) { { 'FOO_BAR' => 'foobar', 'BAZ' => '[1,2,3]', 'QUUX' => 'true' } }
  let(:source_key_dotted) { { 'common.foo.bar' => 'foobar', 'common.baz' => [1, 2, 3], 'common.quux' => true } }
  let(:data_types) { [Array, TrueClass] }

  def consul(k, v, create:1, modify:2)
    # [{"LockIndex":0,"Key":"shard403/cwf_activity_service_v1/new_relic/app_name","Flags":0,"Value":"TkFNRVNQQUNFIENsb3VkIFdvcmtmbG93IEFjdGl2aXR5IFNlcnZpY2UgKEludGVncmF0aW9uKQ==","CreateIndex":144,"ModifyIndex":7661}]
    JSON.dump([{Key: k, Value: Base64.encode64(v), LockIndex: 0, Flags: 0, CreateIndex: create, ModifyIndex: modify}])
  end

  before do
    CMDB::ConsulSource.url = "http://localhost:8500"

    stub_request(:get, "http://localhost:8500/v1/kv/common/common/foo/bar").
      to_return(:status => 200, :body => consul("foo/bar", "foobar"))
    stub_request(:get, "http://localhost:8500/v1/kv/common/common/baz").
      to_return(:status => 200, :body => consul("baz", "[1,2,3]"))
    stub_request(:get, "http://localhost:8500/v1/kv/common/common/quux").
      to_return(:status => 200, :body => consul("quux", "true"))
  end

  subject { CMDB::ConsulSource.new('common') }

  it_behaves_like 'a source'
end
