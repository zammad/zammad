# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class AddAdminBetaUiConfiguration < ActiveRecord::Migration[8.0]
  def up
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.create_if_not_exists(
      title:       'UI Desktop BETA Switch Admin Menu',
      name:        'ui_desktop_beta_switch_admin_menu',
      area:        'UI::Desktop',
      description: 'Allow admins to manage availability and access to the desktop BETA UI switch.',
      state:       false,
      frontend:    true,
    )

    Setting.create_if_not_exists(
      title:       'UI Desktop BETA Switch Roles',
      name:        'ui_desktop_beta_switch_role_ids',
      area:        'UI::Desktop',
      description: 'Defines which roles are allowed to access the desktop UI beta switch.',
      state:       [],
      frontend:    true,
    )

    Permission.create_if_not_exists(
      name:        'admin.beta_ui',
      label:       'BETA UI',
      description: 'Manage BETA UI settings of your system.',
      preferences: {
        prio:    1295,
        setting: {
          name:  'ui_desktop_beta_switch_admin_menu',
          value: true,
        },
      },
    )
  end
end
