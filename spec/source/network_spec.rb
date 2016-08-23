# encoding: utf-8
describe CMDB::Source::Network do
  let(:uri) { URI.parse('http://localhost') }
  let(:prefix) { 'common' }

  subject { described_class.new(uri, prefix) }

  describe '#http_get' do
    it 'retries three times by default' do
      stub_request(:get, 'http://localhost/fail').
        to_return(status: 500, body: 'fall down go boom').
        times(3)

      subject.instance_eval { http_get('/fail') }
    end

    it 'does not retry when asked not to' do
      stub_request(:get, 'http://localhost/fail').
        to_return(status: 500, body: 'fall down go boom').
        times(1)

        subject.instance_eval { http_get('/fail', retries:0) }
    end

    it 'retries more when asked to' do
      stub_request(:get, 'http://localhost/fail').
        to_return(status: 500, body: 'fall down go boom').
        times(10)

        subject.instance_eval { http_get('/fail', retries:10) }
    end
  end
end
