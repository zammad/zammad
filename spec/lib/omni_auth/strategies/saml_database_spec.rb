# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe OmniAuth::Strategies::SamlDatabase do
  describe '.setup' do
    before do
      setting = Setting.find_by(name: 'auth_saml_credentials')
      setting.state_current = { value: {
        'idp_sso_target_url' => 'https://idp.example.com/sso',
        'role_mapping'       => { 'attribute' => 'Role', 'map' => { 'zammad-agent' => [2] } },
      } }
      setting.save!(validate: false)
    end

    it 'does not pass the role mapping on to OmniAuth', :aggregate_failures do
      expect(described_class.setup).to include('idp_sso_target_url' => 'https://idp.example.com/sso')
      expect(described_class.setup).not_to have_key('role_mapping')
    end
  end
end
