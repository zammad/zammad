require 'spec_helper'

describe 'RestClient::Windows::RootCerts',
         :if => RestClient::Platform.windows? do
  let(:x509_store) { RestClient::Windows::RootCerts.instance.to_a }

  it 'should return at least one X509 certificate' do
    expect(x509_store.to_a).to have_at_least(1).items
  end

  it 'should return an X509 certificate with a subject' do
    x509 = x509_store.first

    expect(x509.subject.to_s).to match(/CN=.*/)
  end

  it 'should return X509 certificate objects' do
    x509_store.each do |cert|
      cert.should be_a(OpenSSL::X509::Certificate)
    end
  end
end
