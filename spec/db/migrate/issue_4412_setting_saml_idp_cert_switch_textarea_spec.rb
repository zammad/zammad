# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Issue4412SettingSamlIdpCertSwitchTextarea, type: :db_migration do
  before do
    old_saml_form = Setting.find_by(name: 'auth_saml_credentials').options[:form]
    old_saml_form[3][:tag] = 'input'

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

  let(:migrated_setting_tag) { 'textarea' }

  it 'does migrate auth_saml_credentials setting' do
    expect(Setting.find_by(name: 'auth_saml_credentials').options[:form][3][:tag]).to eq(migrated_setting_tag)
  end
end
