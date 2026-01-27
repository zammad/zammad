# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class AddSnipeitIntegration < ActiveRecord::Migration[7.0]
  def up
    return if !Setting.exists?(name: 'system_init_done')

    Setting.create_if_not_exists(
      title:       'Snipe-IT integration',
      name:        'snipeit_integration',
      area:        'Integration::Switch',
      description: 'Defines if the Snipe-IT (https://snipeitapp.com/) integration is enabled or not.',
      options:     {
        form: [
          {
            display: '',
            null:    true,
            name:    'snipeit_integration',
            tag:     'boolean',
            options: {
              true  => 'yes',
              false => 'no',
            },
          },
        ],
      },
      state:       false,
      preferences: {
        prio:           1,
        authentication: true,
        permission:     ['admin.integration'],
      },
      frontend:    true
    )

    Setting.create_if_not_exists(
      title:       'Snipe-IT config',
      name:        'snipeit_config',
      area:        'Integration::Snipeit',
      description: 'Defines the Snipe-IT config.',
      options:     {},
      state:       {},
      preferences: {
        prio:       2,
        permission: ['admin.integration'],
      },
      frontend:    false,
    )
  end

  def down
    Setting.find_by(name: 'snipeit_integration')&.destroy
    Setting.find_by(name: 'snipeit_config')&.destroy
  end
end
