# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class AddSecureSigningSystemNotificationSettings < ActiveRecord::Migration[8.0]
  def up
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    create_setting(
      title:       'S/MIME signing for system notifications',
      name:        'smime_sign_system_notifications',
      area:        'Integration::SMIME',
      description: 'Defines if system notification emails are S/MIME signed.',
    )
    create_setting(
      title:       'PGP signing for system notifications',
      name:        'pgp_sign_system_notifications',
      area:        'Integration::PGP',
      description: 'Defines if system notification emails are PGP signed.',
    )
  end

  private

  def create_setting(title:, name:, area:, description:)
    Setting.create_if_not_exists(
      title:       title,
      name:        name,
      area:        area,
      description: description,
      options:     {
        form: [
          {
            display: '',
            null:    true,
            name:    name,
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
        prio:       3,
        permission: ['admin.integration'],
      },
      # No real-time WebSocket broadcast needed for this admin toggle.
      frontend:    false,
    )
  end
end
