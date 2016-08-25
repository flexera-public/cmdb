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
  let(:uri) { URI.parse('consul://localhost/common') }
  subject { described_class.new(uri, prefix) }

  before do
    stub_request(:get, 'http://localhost:8500/v1/kv/common/?recurse').
      to_return(:status => 200, :body =>
        consul('common/foo/bar' => 'foobar', 'common/baz' => '[1,2,3]', 'common/quux' => 'true'))
    stub_request(:get, 'http://localhost:8500/v1/kv/common/foo/bar').
      to_return(:status => 200, :body => consul('common/foo/bar' => 'foobar'))
    stub_request(:get, 'http://localhost:8500/v1/kv/common/baz').
      to_return(:status => 200, :body => consul('common/baz' => '[1,2,3]'))
    stub_request(:get, 'http://localhost:8500/v1/kv/common/quux').
      to_return(:status => 200, :body => consul('common/quux' => 'true'))

    stub_request(:put, 'http://localhost:8500/v1/kv/common/i_like_cheese').
      to_return(:status => 200, :body => 'true')
    stub_request(:get, 'http://localhost:8500/v1/kv/common/i_like_cheese').
      to_return(:status => 200, :body => consul('common/i_like_cheese' => 'true'))
  end

  it_behaves_like 'a source'

  it_behaves_like 'a settable source'

  describe '#each_pair' do
    context 'given a deeply nested base path' do
      let(:prefix) { 'common' }
      let(:uri) { URI.parse('consul://localhost/world/continent/country/common') }
      subject { described_class.new(uri, prefix) }

      before do
        stub_request(:get, 'http://localhost:8500/v1/kv/world/continent/country/common/foo/bar').
          to_return(:status => 200, :body =>
            consul('world/continent/country/common/foo/bar' => 'foobar'))
        stub_request(:get, 'http://localhost:8500/v1/kv/world/continent/country/common/?recurse').
          to_return(:status => 200, :body =>
            consul('world/continent/country/common/foo/bar' => 'foobar'))
      end

      it 'uses the prefix alone for key names' do
        expect(subject.get('common.foo.bar')).to eq('foobar')

        values = {}
        subject.each_pair { |k, v| values[k] = v }
        expect(values).to eq('common.foo.bar' => 'foobar')
      end
    end
  end

  describe '#path_to' do
    let(:prefix) { nil }

    context 'given a long base path' do
      let(:uri) { URI.parse('http://localhost:8500/bar/baz') }

      it 'behaves' do
        expect(subject.path_to('quux')).to eq('/v1/kv/bar/baz/quux')
        expect(subject.path_to('/')).to eq('/v1/kv/bar/baz/')
      end
    end

    context 'given a short base path' do
      let(:uri) { URI.parse('http://localhost:8500/bar') }

      it 'behaves' do
        expect(subject.path_to('quux')).to eq('/v1/kv/bar/quux')
        expect(subject.path_to('/')).to eq('/v1/kv/bar/')
      end
    end

    context 'given an empty base path' do
      let(:uri) { URI.parse('http://localhost:8500') }

      it 'behaves' do
        expect(subject.path_to('quux')).to eq('/v1/kv/quux')
        expect(subject.path_to('/')).to eq('/v1/kv/')
      end
    end
  end
end
