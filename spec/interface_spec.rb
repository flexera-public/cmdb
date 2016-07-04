# encoding: utf-8
describe CMDB::Interface do
  @@subject = CMDB::Interface.new
  before(:all) do
    @original_sources = @@subject.instance_variable_get(:@sources)
  end

  after(:all) do
    @@subject.instance_variable_set(:@sources, @original_source)
  end

  let(:source) { double('properly-initialized Source::File') }

  before(:each) do
    subject.instance_variable_set(:@sources, [source])
    allow(source).to receive(:get).with('i_exist').and_return(true)
    allow(source).to receive(:get).with('i_do_not_exist').and_return(nil)
  end

  context '#get' do
    it 'returns key values' do
      expect(subject.get('i_exist')).to eq(true)
    end

    it 'returns nil when the key is missing' do
      expect(subject.get('i_do_not_exist')).to eq(nil)
    end
  end

  context '#get!' do
    it 'returns key values' do
      expect(subject.get!('i_exist')).to eq(true)
    end

    it 'raises when the key is missing' do
      expect { subject.get!('i_do_not_exist') }.to raise_error(CMDB::MissingKey)
    end
  end
end
