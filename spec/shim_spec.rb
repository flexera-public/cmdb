describe CMDB::Commands::Shim do
  describe '.drop_privileges' do
    let(:login) { 'some-random-unix-login' }
    let(:bad_login) { 'some-invalid-login' }
    let(:uid) { 4242 }
    let(:gid) { 4242 }
    let(:pwent) { double(Etc::Passwd, :uid=>uid, :gid=>gid) }

    before do
      allow(Etc).to receive(:getpwnam).with(login).and_return(pwent)
      allow(Etc).to receive(:getpwnam).with(bad_login).and_raise(ArgumentError)
      allow(Process::Sys).to receive(:setresgid).with(gid, gid, gid)
      allow(Process::Sys).to receive(:setresuid).with(uid, uid, uid)
    end

    it 'maps the login to a uid' do
      expect(Etc).to receive(:getpwnam)
      described_class.drop_privileges(login)
    end

    it 'raises when the login does not exist' do
      expect {
        described_class.drop_privileges(bad_login)
      }.to raise_exception(ArgumentError)
    end

    it 'sets the real, effective and saved uids' do
      expect(Process::Sys).to receive(:setresuid).with(uid, uid, uid)
      described_class.drop_privileges(login)
    end

    it 'sets the real, effective and saved gids' do
      expect(Process::Sys).to receive(:setresgid).with(gid, gid, gid)
      described_class.drop_privileges(login)
    end
  end
end