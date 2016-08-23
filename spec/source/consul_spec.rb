# encoding: utf-8
describe CMDB::Source::Consul do
  let(:source_prefix) { 'common' }
  let(:source_data) { { 'common.foo.bar' => 'foobar', 'common.baz' => [1, 2, 3], 'common.quux' => true } }

  # mock up a consul k/v GET response
  def consul(h, create:1, modify:2)
    # [{"LockIndex":0,"Key":"shard403/cwf_activity_service_v1/new_relic/app_name","Flags":0,"Value":"TkFNRVNQQUNFIENsb3VkIFdvcmtmbG93IEFjdGl2aXR5IFNlcnZpY2UgKEludGVncmF0aW9uKQ==","CreateIndex":144,"ModifyIndex":7661}]
    ary = []
    h.each_pair do |k, v|
      ary << {Key: k, Value: Base64.encode64(v), LockIndex: 0, Flags: 0, CreateIndex: create, ModifyIndex: modify}
    end
    JSON.dump(ary)
  end

  let(:prefix) { 'common' }
  let(:uri) { URI.parse('http://localhost:8500/') }
  subject { described_class.new(uri, prefix) }

  before do
    stub_request(:get, 'http://localhost:8500/v1/kv/common/?recurse').
      to_return(:status => 200, :body =>
        consul('foo/bar' => 'foobar', 'baz' => '[1,2,3]', 'quux' => 'true'))
    stub_request(:get, 'http://localhost:8500/v1/kv/common/foo/bar').
      to_return(:status => 200, :body => consul('foo/bar' => 'foobar'))
    stub_request(:get, 'http://localhost:8500/v1/kv/common/baz').
      to_return(:status => 200, :body => consul('baz' => '[1,2,3]'))
    stub_request(:get, 'http://localhost:8500/v1/kv/common/quux').
      to_return(:status => 200, :body => consul('quux' => 'true'))

    stub_request(:put, "http://localhost:8500/v1/kv/common/i_like_cheese").
      to_return(:status => 200, :body => 'true')
    stub_request(:get, 'http://localhost:8500/v1/kv/common/i_like_cheese').
      to_return(:status => 200, :body => consul('i_like_cheese' => 'true'))
  end

  it_behaves_like 'a source'

  it_behaves_like 'a settable source'
end
