# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Issue4263SamlDisplayName, type: :db_migration do
  before do
    Setting.create_or_update(
      title:       __('SAML App Credentials'),
      name:        'auth_saml_credentials',
      area:        'Security::ThirdPartyAuthentication::SAML',
      description: __('Enables user authentication via SAML.'),
      options:     {
        form: [
          {
            display:     __('IDP SSO target URL'),
            null:        true,
            name:        'idp_sso_target_url',
            tag:         'input',
            placeholder: 'https://capriza.github.io/samling/samling.html',
          },
        ],
      }
    )

    migrate
  end

  let(:migrated_setting) do
    {
      display:     __('Display name'),
      null:        true,
      name:        'display_name',
      tag:         'input',
      placeholder: __('SAML'),
    }
  end

  it 'does migrate auth_saml_credentials setting' do
    expect(Setting.find_by(name: 'auth_saml_credentials').options[:form].first).to eq(migrated_setting.deep_stringify_keys)
  end
end
