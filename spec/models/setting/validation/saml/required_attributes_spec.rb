# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Setting::Validation::Saml::RequiredAttributes do

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

  context 'with missing required settings' do
    it 'raises an error' do
      expect { Setting.set(setting_name, { display_name: 'Keycloak', security: 'on' }) }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: One of the required attributes 'idp_sso_target_url', 'idp_slo_service_url', 'idp_cert', 'name_identifier_format' is missing.")
    end
  end
end
