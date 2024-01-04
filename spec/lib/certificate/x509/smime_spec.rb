# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Certificate::X509::SMIME do
  def fixture(name)
    Rails.root.join('spec/fixtures/files/smime', "#{name}.crt").read.strip
  end

  describe '#parse' do
    context 'when certificate is valid' do
      let(:certificate) { fixture('alice@acme.corp+sign+encrypt') }

      it 'returns a certificate' do
        expect(described_class.parse(certificate)).to be_a(described_class)
      end
    end

    context 'when certificate is invalid' do
      let(:certificate) { 'invalid' }

      it 'raises an error' do
        message = 'The certificate is not valid for S/MIME usage. Please check the certificate format.'
        expect { described_class.parse(certificate) }.to raise_error(Exceptions::UnprocessableEntity, message)
      end
    end
  end

  describe '#new' do
    context 'when certificate is valid' do
      let(:certificate) { fixture('alice@acme.corp+sign+encrypt') }

      it 'returns a certificate' do
        expect(described_class.new(certificate)).to be_a(described_class)
          .and have_attributes(
            'email_addresses' => Array,
            'fingerprint'     => String,
            'issuer_hash'     => String,
            'subject_hash'    => String,
            'uid'             => String
          )
      end
    end

    context 'when certificate is invalid' do
      let(:certificate) { 'invalid' }

      it 'raises an error' do
        expect { described_class.new(certificate) }.to raise_error(OpenSSL::X509::CertificateError)
      end
    end
  end

  describe '.ca?' do
    context 'when certificate is a CA' do
      let(:certificate) { fixture('RootCA') }

      it 'returns true' do
        expect(described_class.new(certificate)).to be_ca
      end
    end

    context 'when certificate is not a CA' do
      let(:certificate) { fixture('alice@acme.corp+sign+encrypt') }

      it 'returns false' do
        expect(described_class.new(certificate)).not_to be_ca
      end
    end
  end

  describe '.rsa?' do
    context 'when certificate has RSA key' do
      let(:certificate) { fixture('alice@acme.corp+sign+encrypt') }

      it 'returns true' do
        expect(described_class.new(certificate)).to be_rsa
      end
    end

    context 'when certificate has no RSA key' do
      let(:certificate) { fixture('alice@acme.corp+sign+encrypt+ec') }

      it 'returns false' do
        expect(described_class.new(certificate)).not_to be_rsa
      end
    end
  end

  describe '.ec?' do
    context 'when certificate has EC key' do
      let(:certificate) { fixture('alice@acme.corp+sign+encrypt+ec') }

      it 'returns true' do
        expect(described_class.new(certificate)).to be_ec
      end
    end

    context 'when certificate has no EC key' do
      let(:certificate) { fixture('alice@acme.corp+sign+encrypt') }

      it 'returns false' do
        expect(described_class.new(certificate)).not_to be_ec
      end
    end
  end

  describe '.effective?' do
    context 'when certificate is already valid (not before date is in past)' do
      let(:certificate) { fixture('alice@acme.corp+sign+encrypt') }

      it 'returns true' do
        expect(described_class.new(certificate)).to be_effective
      end
    end

    context 'when certificate is not yet valid (not before date is in future)' do
      let(:certificate) { fixture('alice@acme.corp+sign+encrypt+future') }

      it 'returns false' do
        expect(described_class.new(certificate)).not_to be_effective
      end
    end
  end

  describe '.expired?' do
    context 'when certificate is expired (not after date is in past)' do
      let(:certificate) { fixture('alice@acme.corp+sign+encrypt+expired') }

      it 'returns true' do
        expect(described_class.new(certificate)).to be_expired
      end
    end

    context 'when certificate is not expired (not after date is in future)' do
      let(:certificate) { fixture('alice@acme.corp+sign+encrypt') }

      it 'returns false' do
        expect(described_class.new(certificate)).not_to be_expired
      end
    end
  end

  describe '.signature?' do
    context 'when certificate is usable for signing' do
      let(:certificate) { fixture('alice@acme.corp+sign') }

      it 'returns true' do
        expect(described_class.new(certificate)).to be_signature
      end
    end

    context 'when certificate is not usable for signing' do
      let(:certificate) { fixture('alice@acme.corp+encrypt') }

      it 'returns false' do
        expect(described_class.new(certificate)).not_to be_signature
      end
    end

    context 'when certificate is usable for signing and encrypting' do
      let(:certificate) { fixture('alice@acme.corp+sign+encrypt') }

      it 'returns true' do
        expect(described_class.new(certificate)).to be_signature
      end
    end
  end

  describe '.encryption?' do
    context 'when certificate is usable for encrypting' do
      let(:certificate) { fixture('alice@acme.corp+encrypt') }

      it 'returns true' do
        expect(described_class.new(certificate)).to be_encryption
      end
    end

    context 'when certificate is not usable for encrypting' do
      let(:certificate) { fixture('alice@acme.corp+sign') }

      it 'returns false' do
        expect(described_class.new(certificate)).not_to be_encryption
      end
    end

    context 'when certificate is usable for signing and encrypting' do
      let(:certificate) { fixture('alice@acme.corp+sign+encrypt') }

      it 'returns true' do
        expect(described_class.new(certificate)).to be_encryption
      end
    end
  end

  describe '.applicable?' do
    context 'when certificate has valid extended key usage (E-mail Protection)' do
      let(:certificate) { fixture('alice@acme.corp+sign+encrypt') }

      it 'returns true' do
        expect(described_class.new(certificate)).to be_applicable
      end
    end

    context 'when certificate has no valid extended key usage (E-mail Protection)' do
      let(:certificate) { fixture('zammad.com') }

      it 'returns false' do
        expect(described_class.new(certificate)).not_to be_applicable
      end
    end
  end

  describe '.usable?' do
    context 'when certificate is effective and not expired' do
      let(:certificate) { fixture('alice@acme.corp+sign+encrypt') }

      it 'returns true' do
        expect(described_class.new(certificate)).to be_usable
      end
    end

    context 'when certificate is expired' do
      let(:certificate) { fixture('alice@acme.corp+sign+encrypt+expired') }

      it 'returns false' do
        expect(described_class.new(certificate)).not_to be_usable
      end
    end

    context 'when certificate is not yet effective' do
      let(:certificate) { fixture('alice@acme.corp+sign+encrypt+future') }

      it 'returns false' do
        expect(described_class.new(certificate)).not_to be_usable
      end
    end
  end

  describe '.valid_smime_certificate?' do
    context 'when certificate is issued for SMIME usage' do
      let(:certificate) { fixture('alice@acme.corp+sign+encrypt+expired') }

      it 'returns true' do
        expect(described_class.new(certificate)).to be_valid_smime_certificate
      end
    end

    context 'when certificate is not issued for SMIME usage' do
      let(:certificate) { fixture('zammad.com') }

      it 'returns false' do
        expect(described_class.new(certificate)).not_to be_valid_smime_certificate
      end
    end
  end

  describe '.valid_smime_certificate!' do
    context 'when certificate is issued for SMIME usage' do
      let(:certificate) { fixture('alice@acme.corp+sign+encrypt+expired') }

      it 'raises no exception' do
        expect { described_class.new(certificate).valid_smime_certificate! }.not_to raise_error
      end
    end

    context 'when certificate is not issued for SMIME usage' do
      let(:certificate) { fixture('zammad.com') }

      it 'returns false' do
        message = 'The certificate is not valid for S/MIME usage. Please check the key usage, subject alternative name and public key cryptographic algorithm.'
        expect { described_class.new(certificate).valid_smime_certificate! }.to raise_error(Exceptions::UnprocessableEntity, message)
      end
    end
  end

end
