# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Issue3245Office365MicrosoftRename, type: :db_migration do
  it 'renames Office 365 to Microsoft' do
    replace_setting_with_old

    migrate

    new_setting = Setting.find_by(name: 'auth_microsoft_office365')

    expect(new_setting.preferences).to include(title_i18n: ['Microsoft'], description_i18n: ['Microsoft', 'Microsoft Application Registration Portal', 'https://portal.azure.com'])
  end

  def replace_setting_with_old
    Setting
      .find_by(name: 'auth_microsoft_office365')
      .destroy!

    Setting.create!(
      title:       'Authentication via %s',
      name:        'auth_microsoft_office365',
      area:        'Security::ThirdPartyAuthentication',
      description: 'Enables user authentication via %s. Register your app first at [%s](%s).',
      options:     {
        form: [
          {
            display: '',
            null:    true,
            name:    'auth_microsoft_office365',
            tag:     'boolean',
            options: {
              true  => 'yes',
              false => 'no',
            },
          },
        ],
      },
      preferences: {
        controller:       'SettingsAreaSwitch',
        sub:              ['auth_microsoft_office365_credentials'],
        title_i18n:       ['Microsoft'],
        description_i18n: ['Microsoft', 'Microsoft Application Registration Portal', 'https://portal.azure.com'],
        permission:       ['admin.security'],
      },
      state:       false,
      frontend:    true
    )
  end
end
