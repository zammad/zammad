# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

FIXTURES_FILES_PATH = Rails.root.join('spec/fixtures/files/pgp').freeze

RSpec.describe SecureMailing::PGP::Tool, :aggregate_failures do

  before do
    Setting.set('pgp_integration', true)
  end

  let(:instance) { described_class.new }

  describe '#with_private_keyring' do
    it 'sets GNUPGHOME to a temporary directory' do
      expect(instance.with_private_keyring(&:gnupg_home)).to be_present
      expect(instance.with_private_keyring { |t| File.exist?("#{t.gnupg_home}/pubring.kbx") }).to be false
      expect(instance.with_private_keyring do |t|
               t.send(:gpg, 'list-keys')
               File.exist?("#{t.gnupg_home}/pubring.kbx")
             end).to be true
    end

    it 'removes the temporary directory afterwards' do
      expect(Dir.exist?(instance.with_private_keyring(&:gnupg_home))).to be false
    end
  end

  describe '#call (private method)' do
    it 'only works from with_private_keyring' do
      expect { instance.send(:gpg, 'version') }.to raise_error(RuntimeError)
    end
  end

  describe '#import' do
    let(:key) { FIXTURES_FILES_PATH.join('zammad@localhost.pub.asc').read }
    let(:private_key) { FIXTURES_FILES_PATH.join('zammad@localhost.asc').read }

    let(:import) do
      instance.with_private_keyring do |t|
        t.import(private_key)
        t.import(key)
      end
    end

    it 'imports public and private keys successfully' do
      expect(import.status.success?).to be true
      expect(import.stdout).to be_empty
    end

    context 'with an invalid key' do
      let(:key) { 'invalid' }

      it 'raises an error' do
        expect { import }.to raise_error(SecureMailing::PGP::Tool::Error::NoData)
      end
    end
  end

  describe '#passphrase' do
    let(:private_key) { FIXTURES_FILES_PATH.join('zammad@localhost.asc').read }
    let(:fingerprint) { FIXTURES_FILES_PATH.join('zammad@localhost.fingerprint').read }
    let(:passphrase)  { FIXTURES_FILES_PATH.join('zammad@localhost.passphrase').read }

    let(:passphrase_result) do
      instance.with_private_keyring do |t|
        t.import(private_key)
        t.passphrase(fingerprint, passphrase)
      end
    end

    it 'validates the passphrase successfully' do
      expect(passphrase_result.status.success?).to be true
    end

    context 'with an invalid passphrase' do
      let(:passphrase) { 'invalid' }

      it 'raises an error' do
        expect { passphrase_result }.to raise_error(SecureMailing::PGP::Tool::Error::BadPassphrase)
      end
    end

    context 'with an empty passphrase' do
      let(:passphrase) { '' }

      it 'raises an error' do
        expect { passphrase_result }.to raise_error(SecureMailing::PGP::Tool::Error::NoPassphrase)
      end
    end

  end

  describe '#info' do
    let(:key)         { FIXTURES_FILES_PATH.join('zammad@localhost.pub.asc').read }
    let(:fingerprint) { FIXTURES_FILES_PATH.join('zammad@localhost.fingerprint').read }
    let(:created_at)  { DateTime.parse(FIXTURES_FILES_PATH.join('zammad@localhost.created_at').read) }
    let(:expires_at)  { DateTime.parse(FIXTURES_FILES_PATH.join('zammad@localhost.expires_at').read) }

    let(:info) do
      instance.with_private_keyring { |t| t.info(key) }
    end

    it 'returns information of a public key successfully' do
      expect(info).to have_attributes(fingerprint: fingerprint, uids: ['zammad@localhost'], created_at: created_at, expires_at: expires_at, secret: false)
    end

    context 'with an invalid key' do
      let(:key) { 'invalid' }

      it 'raises an error' do
        expect { info }.to raise_error(SecureMailing::PGP::Tool::Error::NoData)
      end
    end

    context 'with an key including a revoke subkey' do
      let(:key)         { FIXTURES_FILES_PATH.join('zammad@localhost.revoker.pub.asc').read }
      let(:fingerprint) { FIXTURES_FILES_PATH.join('zammad@localhost.revoker.fingerprint').read }
      let(:created_at)  { DateTime.parse(FIXTURES_FILES_PATH.join('zammad@localhost.revoker.created_at').read) }
      let(:expires_at)  { DateTime.parse(FIXTURES_FILES_PATH.join('zammad@localhost.revoker.expires_at').read) }

      it 'returns information of a public key successfully' do
        expect(info).to have_attributes(fingerprint: fingerprint, uids: ['zammad@localhost'], created_at: created_at, expires_at: expires_at, secret: false)
      end
    end

    context 'with an key including a revoked uid' do
      let(:key)         { FIXTURES_FILES_PATH.join('zammad@localhost.revuid.pub.asc').read }
      let(:fingerprint) { FIXTURES_FILES_PATH.join('zammad@localhost.revuid.fingerprint').read }
      let(:created_at)  { DateTime.parse(FIXTURES_FILES_PATH.join('zammad@localhost.revuid.created_at').read) }
      let(:expires_at)  { nil }
      let(:revuid)      { FIXTURES_FILES_PATH.join('zammad@localhost.revuid.uid').read }

      it 'returns information of a public key successfully' do
        expect(info.uids.exclude?(revuid)).to be true
        expect(info).to have_attributes(fingerprint: fingerprint, uids: ['zammad@localhost'], created_at: created_at, expires_at: expires_at, secret: false)
      end
    end
  end

  describe '#export' do
    let(:fingerprint) { FIXTURES_FILES_PATH.join('zammad@localhost.fingerprint').read }

    let(:export) do
      instance.with_private_keyring do |t|
        t.import(key)
        t.export(fingerprint, passphrase, secret: secret)
      end
    end

    context 'with public key' do
      let(:key)        { FIXTURES_FILES_PATH.join('zammad@localhost.pub.asc').read }
      let(:passphrase) { nil }
      let(:secret)     { false }

      it 'exports a public key successfully' do
        expect(export.status.success?).to be true
        expect(export.stdout).to eq(key)
      end

      context 'with an unknown fingerprint' do
        let(:fingerprint) { 'invalid' }

        it 'raises an error' do
          expect { export }.to raise_error(SecureMailing::PGP::Tool::Error::NoPublicKey)
        end
      end
    end

    context 'with private key' do
      let(:key)        { FIXTURES_FILES_PATH.join('zammad@localhost.asc').read }
      let(:passphrase) { FIXTURES_FILES_PATH.join('zammad@localhost.passphrase').read }
      let(:secret)     { true }

      let(:info) do
        described_class.new.with_private_keyring do |t|
          t.info(key)
        end
      end

      it 'exports a private key successfully' do
        # The exported key differs from the imported key because the exported key is encrypted with a random salt.
        # For that we compare the key information instead of the key itself.
        expect(described_class.new.with_private_keyring { |t| t.info(export.stdout) }).to eq(info)
      end

      context 'with an unknown fingerprint' do
        let(:fingerprint) { 'invalid' }

        it 'raises an error' do
          expect { export }.to raise_error(SecureMailing::PGP::Tool::Error::NoSecretKey)
        end
      end
    end
  end

  describe '#sign' do
    let(:key)         { FIXTURES_FILES_PATH.join('zammad@localhost.asc').read }
    let(:passphrase)  { FIXTURES_FILES_PATH.join('zammad@localhost.passphrase').read }
    let(:fingerprint) { FIXTURES_FILES_PATH.join('zammad@localhost.fingerprint').read }
    let(:data)        { 'Hello, World.' }

    let(:sign) do
      instance.with_private_keyring do |t|
        t.import(key)
        t.sign(data, fingerprint, passphrase)
      end
    end

    it 'signs data successfully' do
      expect(sign.status.success?).to be true
      expect(sign.stdout).to be_present and expect(sign.stdout).to include('-----BEGIN PGP SIGNATURE-----')
    end

    context 'with an invalid passphrase' do
      let(:passphrase) { 'invalid' }

      it 'raises an error' do
        expect { sign }.to raise_error(SecureMailing::PGP::Tool::Error::BadPassphrase)
      end
    end
  end

  describe '#verify' do
    let(:key)         { FIXTURES_FILES_PATH.join('zammad@localhost.asc').read }
    let(:passphrase)  { FIXTURES_FILES_PATH.join('zammad@localhost.passphrase').read }
    let(:fingerprint) { FIXTURES_FILES_PATH.join('zammad@localhost.fingerprint').read }
    let(:data)        { FIXTURES_FILES_PATH.join('zammad@localhost.data').read }
    let(:signature)   { FIXTURES_FILES_PATH.join('zammad@localhost.data.sig.asc').read }

    let(:verify) do
      instance.with_private_keyring do |t|
        t.import(key) if key.present?
        t.verify(data, signature: signature)
      end
    end

    it 'verifies signature successfully' do
      expect(verify.status.success?).to be true
      expect(verify.stderr).to be_present and expect(verify.stderr).to include('Good signature')
    end

    context 'with corrupted data' do
      let(:data) { 'invalid' }

      it 'raises an error' do
        expect { verify }.to raise_error(SecureMailing::PGP::Tool::Error::BadSignature)
      end
    end

    context 'with an invalid signature' do
      let(:signature) { 'invalid' }

      it 'raises an error' do
        expect { verify }.to raise_error(SecureMailing::PGP::Tool::Error::NoData)
      end
    end

    context 'with an missing public key' do
      let(:key) { nil }

      it 'raises an error' do
        expect { verify }.to raise_error(SecureMailing::PGP::Tool::Error::NoPublicKey)
      end
    end
  end

  describe '#encrypt' do
    let(:key)         { FIXTURES_FILES_PATH.join('zammad@localhost.asc').read }
    let(:passphrase)  { FIXTURES_FILES_PATH.join('zammad@localhost.passphrase').read }
    let(:fingerprint) { FIXTURES_FILES_PATH.join('zammad@localhost.fingerprint').read }
    let(:data)        { 'Hello, World.' }

    let(:encrypt) do
      instance.with_private_keyring do |t|
        t.import(key)
        t.encrypt(data, [fingerprint])
      end
    end

    it 'encrypts data successfully' do
      expect(encrypt.status.success?).to be true
      expect(encrypt.stdout).to be_present and expect(encrypt.stdout).to include('-----BEGIN PGP MESSAGE-----')
    end

    context 'with an unknown recipient' do
      let(:fingerprint) { 'invalid' }

      it 'raises an error' do
        expect { encrypt }.to raise_error(SecureMailing::PGP::Tool::Error::InvalidRecipient)
      end
    end
  end

  describe '#decrypt' do
    let(:key)            { FIXTURES_FILES_PATH.join('zammad@localhost.asc').read }
    let(:passphrase)     { FIXTURES_FILES_PATH.join('zammad@localhost.passphrase').read }
    let(:fingerprint)    { FIXTURES_FILES_PATH.join('zammad@localhost.fingerprint').read }
    let(:encrypted_data) { FIXTURES_FILES_PATH.join('zammad@localhost.data.enc.asc').read }

    let(:decrypt) do
      instance.with_private_keyring do |t|
        t.import(key)
        t.decrypt(encrypted_data, passphrase)
      end
    end

    it 'decrypts data successfully' do
      expect(decrypt.status.success?).to be true
      expect(decrypt.stdout).to eq("Hello, World.\n")
    end

    context 'with an invalid passphrase' do
      let(:passphrase) { 'invalid' }

      it 'raises an error' do
        expect { decrypt }.to raise_error(SecureMailing::PGP::Tool::Error::BadPassphrase)
      end
    end
  end
end
