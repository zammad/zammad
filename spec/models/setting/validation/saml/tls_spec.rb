# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

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

      it 'raises an error' do
        expect { Setting.set(setting_name, setting_value) }.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: The verification of the TLS connection failed. Please check the IDP certificate.')
      end
    end
  end
end
