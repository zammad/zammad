# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Issue4411SettingSamlCustomUidAttribute, type: :db_migration do
  before do
    old_saml_form = Setting.find_by(name: 'auth_saml_credentials').options[:form]
    old_saml_form.delete_at(-2)

    Setting.create_or_update(
      title:       __('SAML App Credentials'),
      name:        'auth_saml_credentials',
      area:        'Security::ThirdPartyAuthentication::SAML',
      description: __('Enables user authentication via SAML.'),
      options:     {
        form: old_saml_form
      }
    )

    migrate
  end

  let(:migrated_setting) do
    {
      display:     'UID Attribute Name',
      null:        true,
      name:        'uid_attribute',
      tag:         'input',
      placeholder: '',
      help:        'Attribute that uniquely identifies the user. If unset, the name identifier returned by the IDP is used.',
    }
  end

  it 'does migrate auth_saml_credentials setting' do
    expect(Setting.find_by(name: 'auth_saml_credentials').options[:form][-2]).to eq(migrated_setting.deep_stringify_keys)
  end
end
