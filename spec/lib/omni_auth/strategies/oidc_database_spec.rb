# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe OmniAuth::Strategies::OidcDatabase do
  describe '.setup' do
    before do
      Setting.set('auth_openid_connect_credentials', {
                    'identifier'   => 'zammad',
                    'issuer'       => 'https://idp.example.com/realms/zammad',
                    'role_mapping' => { 'attribute' => 'roles', 'map' => { 'zammad-agent' => [2] } },
                  })
    end

    it 'does not pass the role mapping on to OmniAuth', :aggregate_failures do
      expect(described_class.setup).to include('identifier' => 'zammad')
      expect(described_class.setup).not_to have_key('role_mapping')
    end
  end
end
