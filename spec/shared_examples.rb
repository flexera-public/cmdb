# encoding: utf-8
# Givens (must be declared in outer #let):
#  - source_prefix, a String e.g. "common." or nil/""
#  - source_key_env, Hash of env key names e.g. 'FOO' to expected values
#  - source_key_dotted, Array of dotted-underscore key names e.g. 'common.foo' to expected values
#  - data_types, Array of types represented in data
RSpec.shared_examples 'a source' do
  describe '#get' do
    it 'accepts keys with prefixes' do
      source_key_dotted.each do |k, expected|
        expect(subject.get(k)).to eq(expected)
      end
    end

    it 'returns Object values' do
      types = Set.new
      source_key_dotted.each do |_k, v|
        types << v.class
      end

      data_types.each { |dt| expect(types).to include(dt) }
    end
  end

  describe '#each_pair' do
    let(:hash) do
      h = {}; source_key_env.each_pair { |k, v| h[k] = v }; h
      h
    end

    it 'yields env-compatible keys' do
      source_key_env.each do |k, expected|
        expect(hash[k]).to eq(expected)
      end
    end

    it 'yields String values' do
      hash.each_value.each { |v| expect(v).to be_a(String) }
    end
  end
end
