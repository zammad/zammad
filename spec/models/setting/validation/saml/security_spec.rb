# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Setting::Validation::Saml::Security do
  let(:setting_name) { 'auth_saml_credentials' }

  let(:setting_value) do
    {
      idp_sso_target_url:     'https://self-signed.badssl.com/',
      idp_slo_service_url:    'https://example.com',
      name_identifier_format: 'urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress',
      idp_cert:               '-----BEGIN CERTIFICATE-----...-----END CERTIFICATE-----',
      ssl_verify:             false,
      security:               security,
      private_key:            private_key_pem,
      private_key_secret:     private_key_secret,
      certificate:            certificate,
    }
  end

  let(:security)           { 'on' }
  let(:private_key_pem)    { OpenSSL::PKey::RSA.generate('2048').to_pem }
  let(:private_key_secret) { '' }

  let(:certificate) do
    private_key = private_key_pem.blank? ? OpenSSL::PKey::RSA.generate('2048') : OpenSSL::PKey.read(private_key_pem)
    create_certificate(private_key)
  end

  def create_certificate(private_key, expired: false, ca_cert: false, usable: true)
    cert = OpenSSL::X509::Certificate.new
    cert.subject    = cert.issuer = OpenSSL::X509::Name.parse('/CN=Acme')
    cert.not_before = Time.zone.now
    cert.not_after  = Time.zone.now + (365 * 24 * 60 * 60)
    cert.public_key = private_key.public_key if private_key.respond_to?(:public_key)
    cert.serial     = 0x0
    cert.version    = 2

    cert.not_after = Time.zone.now - (365 * 24 * 60 * 60) if expired

    ef                     = OpenSSL::X509::ExtensionFactory.new
    ef.subject_certificate = cert
    ef.issuer_certificate  = cert

    certificate_extensions(cert, ef, ca_cert:, usable:)

    cert.sign(private_key, OpenSSL::Digest.new('SHA256'))

    cert.to_pem
  end

  def certificate_extensions(cert, extension_factory, ca_cert: false, usable: true)
    cert.add_extension(extension_factory.create_extension('basicConstraints', 'CA:TRUE', true)) if ca_cert
    cert.add_extension(extension_factory.create_extension('subjectKeyIdentifier', 'hash', false))
    cert.add_extension(extension_factory.create_extension('keyUsage', usable ? 'digitalSignature,keyEncipherment' : 'cRLSign', true))

    cert.add_extension(extension_factory.create_extension('authorityKeyIdentifier', 'keyid:always,issuer:always', false))
  end

  context 'with blank settings' do
    it 'does not raise an error' do
      expect { Setting.set(setting_name, {}) }.not_to raise_error
    end
  end

  context 'with no security' do
    let(:security) { 'off' }

    it 'does not raise an error' do
      expect { Setting.set(setting_name, {}) }.not_to raise_error
    end
  end

  context 'with missing prerequisites' do
    context 'when certificate is missing' do
      let(:certificate) { '' }

      it 'raises an error' do
        expect { Setting.set(setting_name, setting_value) }.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: No certificate found.')
      end
    end

    context 'when private key is missing' do
      let(:private_key_pem) { '' }

      it 'raises an error' do
        expect { Setting.set(setting_name, setting_value) }.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: No private key found.')
      end
    end
  end

  context 'when private key has wrong type' do
    let(:certificate)     { create_certificate(OpenSSL::PKey::RSA.generate('2048')) }
    let(:private_key_pem) { OpenSSL::PKey::EC.generate('prime256v1').to_pem }

    it 'raises an error' do
      expect { Setting.set(setting_name, setting_value) }.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: The type of the private key is wrong.')
    end
  end

  context 'when private key has wrong length' do
    let(:private_key_pem) { OpenSSL::PKey::RSA.generate('1024').to_pem }

    it 'raises an error' do
      expect { Setting.set(setting_name, setting_value) }.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: The length of the private key is too short.')
    end
  end

  context 'when certificate contains non-parsable content' do
    let(:certificate) { 'dummy' }

    it 'raises an error' do
      expect { Setting.set(setting_name, setting_value) }.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: The certificate could not be parsed.')
    end
  end

  context 'when certificate is a CA certificate' do
    let(:certificate) { create_certificate(OpenSSL::PKey.read(private_key_pem), ca_cert: true) }

    it 'raises an error' do
      expect { Setting.set(setting_name, setting_value) }.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: The certificate is not usable due to being a CA certificate.')
    end
  end

  context 'when certificate is not usable (e.g. expired)' do
    let(:certificate) { create_certificate(OpenSSL::PKey.read(private_key_pem), expired: true) }

    it 'raises an error' do
      expect { Setting.set(setting_name, setting_value) }.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: The certificate is not usable (e.g. expired).')
    end
  end

  context 'when certificate is not usable for signing/encrypting' do
    let(:certificate) { create_certificate(OpenSSL::PKey.read(private_key_pem), usable: false) }

    it 'raises an error' do
      expect { Setting.set(setting_name, setting_value) }.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: The certificate is not usable for signing and encryption.')
    end
  end

  context 'when certificate does not match the private key' do
    let(:private_key_pem) { OpenSSL::PKey::RSA.generate('2048').to_pem }
    let(:certificate)     { create_certificate(OpenSSL::PKey::RSA.generate('2048')) }

    it 'raises an error' do
      expect { Setting.set(setting_name, setting_value) }.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: The certificate does not match the given private key.')
    end
  end

  context 'with a valid certificate and private key' do
    it 'does not raise an error' do
      expect { Setting.set(setting_name, setting_value) }.not_to raise_error
    end
  end
end
