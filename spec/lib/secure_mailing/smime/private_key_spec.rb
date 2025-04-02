# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe SecureMailing::SMIME::PrivateKey do
  def fixture(name, type = :key)
    Rails.root.join('spec/fixtures/files/smime', "#{name}.#{type}").read.strip
  end

  describe '#read' do
    context 'when private key is valid' do
      let(:key)    { fixture('alice@acme.corp+sign+encrypt', :key) }
      let(:secret) { fixture('alice@acme.corp+sign+encrypt', :secret) }

      it 'returns a private key' do
        expect(described_class.read(key, secret)).to be_a(described_class)
      end
    end

    context 'when private key is invalid' do
      let(:key) { 'invalid' }
      let(:secret) { fixture('alice@acme.corp+sign+encrypt', :secret) }

      it 'raises an error' do
        message = 'The private key is not valid for S/MIME usage. Please check the key format and the secret.'
        expect { described_class.read(key, secret) }.to raise_error(Exceptions::UnprocessableEntity, message)
      end
    end

    context 'when private key secret is invalid' do
      let(:key)    { fixture('alice@acme.corp+sign+encrypt', :key) }
      let(:secret) { 'alicelovesbob' }

      it 'raises an error' do
        message = 'The private key is not valid for S/MIME usage. Please check the key format and the secret.'
        expect { described_class.read(key, secret) }.to raise_error(Exceptions::UnprocessableEntity, message)
      end
    end
  end

  describe '#new' do
    context 'when private key is valid' do
      let(:key)    { fixture('alice@acme.corp+sign+encrypt', :key) }
      let(:secret) { fixture('alice@acme.corp+sign+encrypt', :secret) }

      it 'returns a private key' do
        expect(described_class.new(key, secret)).to be_a(described_class)
          .and have_attributes(
            'secret' => String,
            'pem'    => String,
            'uid'    => String
          )
      end
    end

    context 'when private key is invalid' do
      let(:key) { 'invalid' }
      let(:secret) { fixture('alice@acme.corp+sign+encrypt', :secret) }

      it 'raises an error' do
        expect { described_class.new(key, secret) }.to raise_error(OpenSSL::PKey::PKeyError)
      end
    end

    context 'when private key secret is invalid' do
      let(:key)    { fixture('alice@acme.corp+sign+encrypt', :key) }
      let(:secret) { 'alicelovesbob' }

      it 'raises an error' do
        expect { described_class.new(key, secret) }.to raise_error(OpenSSL::PKey::PKeyError)
      end
    end
  end

  describe '.rsa?' do
    context 'when private key is RSA' do
      let(:key)    { fixture('alice@acme.corp+sign+encrypt', :key) }
      let(:secret) { fixture('alice@acme.corp+sign+encrypt', :secret) }

      it 'returns true' do
        expect(described_class.new(key, secret)).to be_rsa
      end
    end

    context 'when private key is not RSA' do
      let(:key)    { fixture('alice@acme.corp+sign+encrypt+ec', :key) }
      let(:secret) { fixture('alice@acme.corp+sign+encrypt+ec', :secret) }

      it 'returns false' do
        expect(described_class.new(key, secret)).not_to be_rsa
      end
    end
  end

  describe '.ec?' do
    context 'when private key is EC' do
      let(:key)    { fixture('alice@acme.corp+sign+encrypt+ec', :key) }
      let(:secret) { fixture('alice@acme.corp+sign+encrypt+ec', :secret) }

      it 'returns true' do
        expect(described_class.new(key, secret)).to be_ec
      end
    end

    context 'when private key is not EC' do
      let(:key)    { fixture('alice@acme.corp+sign+encrypt', :key) }
      let(:secret) { fixture('alice@acme.corp+sign+encrypt', :secret) }

      it 'returns false' do
        expect(described_class.new(key, secret)).not_to be_ec
      end
    end
  end

  describe '.valid_smime_private_key?' do
    context 'when private key is valid (EC)' do
      let(:key)    { fixture('alice@acme.corp+sign+encrypt+ec', :key) }
      let(:secret) { fixture('alice@acme.corp+sign+encrypt+ec', :secret) }

      it 'returns true' do
        expect(described_class.new(key, secret)).to be_valid_smime_private_key
      end
    end

    context 'when private key is valid (RSA)' do
      let(:key)    { fixture('alice@acme.corp+sign+encrypt', :key) }
      let(:secret) { fixture('alice@acme.corp+sign+encrypt', :secret) }

      it 'returns true' do
        expect(described_class.new(key, secret)).to be_valid_smime_private_key
      end
    end

    context 'when private key is invalid (DSA)' do
      let(:key)    { fixture('DSA', :key) }
      let(:secret) { fixture('DSA', :secret) }

      it 'returns true' do
        expect(described_class.new(key, secret)).not_to be_valid_smime_private_key
      end
    end
  end

  describe '.valid_smime_private_key!' do
    context 'when private key is valid (EC)' do
      let(:key)    { fixture('alice@acme.corp+sign+encrypt+ec', :key) }
      let(:secret) { fixture('alice@acme.corp+sign+encrypt+ec', :secret) }

      it 'returns true' do
        expect { described_class.new(key, secret).valid_smime_private_key! }.not_to raise_error
      end
    end

    context 'when private key is valid (RSA)' do
      let(:key)    { fixture('alice@acme.corp+sign+encrypt', :key) }
      let(:secret) { fixture('alice@acme.corp+sign+encrypt', :secret) }

      it 'returns true' do
        expect { described_class.new(key, secret).valid_smime_private_key! }.not_to raise_error
      end
    end

    context 'when private key is invalid (DSA)' do
      let(:key)    { fixture('DSA', :key) }
      let(:secret) { fixture('DSA', :secret) }

      it 'returns true' do
        message = 'The private key is not valid for S/MIME usage. Please check the key cryptographic algorithm.'
        expect { described_class.new(key, secret).valid_smime_private_key! }.to raise_error(Exceptions::UnprocessableEntity, message)
      end
    end
  end

end
