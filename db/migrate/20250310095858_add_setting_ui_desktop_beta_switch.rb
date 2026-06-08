# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class AddSettingUiDesktopBetaSwitch < ActiveRecord::Migration[7.2]
  def up
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.create_if_not_exists(
      title:       'UI Desktop Beta Switch',
      name:        'ui_desktop_beta_switch',
      area:        'UI::Desktop',
      description: 'Allow users to switch automatically to the new desktop UI.',
      state:       false,
      frontend:    true,
    )

    Permission.create_if_not_exists(
      name:         'user_preferences.beta_ui_switch',
      label:        'New BETA UI Switch',
      description:  'Manage access to New BETA UI switch.',
      preferences:  {
        prio: 1710,
      },
      allow_signup: true,
    )
  end
end
