# encoding: utf-8

# Givens (must be declared in outer #let):
#  - source_prefix, a String e.g. "common." or nil/""
#  - source_data, Array of dotted-underscore key names e.g. 'common.foo' to expected values
RSpec.shared_examples 'a source' do
  describe '#get' do
    it 'returns values' do
      source_data.each do |k, expected|
        expect(subject.get(k)).to eq(expected)
      end
    end

    it 'ignores invalid keys' do
      unless source_prefix.nil?
        expect(subject.get('sdfsauydfiasudyfisuyfs.very.unlikely')).to eq(nil)
      end
    end

    it 'returns Object values' do
      expected_types = Set.new
      source_data.each do |k, v|
        expect(subject.get(k)).to eq(v)
      end
    end
  end

  describe '#each_pair' do
    let(:result) do
      h = {}; subject.each_pair { |k, v| h[k] = v }; h
    end

    it 'yields every key/value pair' do
      expect(result.keys.sort).to eq(source_data.keys.sort)
    end

    it 'yields keys with prefixes' do
      result.keys.each { |k| expect(k.index(source_prefix)).to eq(0) }
    end

    it 'yields Object values' do
      expect(result).to eq(source_data)
    end
  end
end

# Givens (must be declared in outer #let):
#  - source_prefix, a String e.g. "common." or nil/""
RSpec.shared_examples 'a settable source' do
  describe '#set' do
    let(:key) { "#{subject.prefix}.i_like_cheese" }

    it 'updates keys' do
      subject.set(key, true)
      expect(subject.get(key)).to eq(true)
    end

    it 'returns nil given an invalid prefix' do
      expect(
        subject.set('sfkuysdfiuyasiuys.unlikely', true)
      ).to eq(nil)
    end
  end
end