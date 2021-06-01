# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class SettingUserOrganizationSelectorWithEmail < ActiveRecord::Migration[5.1]
  def up

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.create_if_not_exists(
      title:       'User Organization Selector - email',
      name:        'ui_user_organization_selector_with_email',
      area:        'UI::UserOrganizatiomSelector',
      description: 'Display of the e-mail in the result of the user/organization widget.',
      options:     {
        form: [
          {
            display:   '',
            null:      true,
            name:      'ui_user_organization_selector_with_email',
            tag:       'boolean',
            translate: true,
            options:   {
              true  => 'yes',
              false => 'no',
            },
          },
        ],
      },
      state:       false,
      preferences: {
        prio:       100,
        permission: ['admin.ui'],
      },
      frontend:    true
    )
  end
end
