# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Setting::Validation::Saml::TLS do

  let(:setting_name) { 'auth_saml_credentials' }

  context 'with blank settings' do
    it 'does not raise an error' do
      expect { Setting.set(setting_name, {}) }.not_to raise_error
    end
  end

  context 'when changing only display_name' do
    it 'does not raise an error' do
      expect { Setting.set(setting_name, { display_name: 'Keycloak' }) }.not_to raise_error
    end
  end

  context 'with self-signed certificate' do
    let(:setting_value) do
      {
        idp_sso_target_url:     'https://self-signed.badssl.com/',
        idp_slo_service_url:    'https://example.com',
        name_identifier_format: 'urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress',
        idp_cert:               '-----BEGIN CERTIFICATE-----...-----END CERTIFICATE-----',
        ssl_verify:             ssl_verify,
      }
    end

    context 'when ssl verify is disabled' do
      let(:ssl_verify) { false }

      it 'does not raise an error' do
        expect { Setting.set(setting_name, setting_value) }.not_to raise_error
      end
    end

    context 'when ssl verify is enabled' do
      let(:ssl_verify) { true }

      context 'with a SSL error' do
        it 'raises an error' do
          if ENV['CI'].present?
            result = UserAgent::Result.new(success: false, error: '#<OpenSSL::SSL::SSLError: SSL_connect returned=1 errno=0 peeraddr=')
            allow(UserAgent).to receive(:get).and_return(result)
          end

          expect { Setting.set(setting_name, setting_value) }.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: The verification of the TLS connection failed. Please check the SAML IDP certificate.')
        end
      end

      context 'with a HTTP error' do
        it 'raises no error' do
          result = UserAgent::Result.new(success: false, error: '#<Net::HTTPNotFound')
          allow(UserAgent).to receive(:get).and_return(result)

          expect { Setting.set(setting_name, setting_value) }.not_to raise_error
        end
      end

      context 'with a connection error' do
        it 'raises an error' do
          result = UserAgent::Result.new(success: false, error: '#<Errno::EHOSTUNREACH')
          allow(UserAgent).to receive(:get).and_return(result)

          expect { Setting.set(setting_name, setting_value) }.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: The verification of the TLS connection is not possible. Please check the SAML IDP connection.')
        end
      end
    end
  end
end
