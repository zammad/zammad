# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class WebPushVapidKeys < ActiveRecord::Migration[8.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    vapid_key = WebPush.generate_key

    Setting.create_if_not_exists(
      title:       'Web Push VAPID Private Key',
      name:        'web_push_vapid_private_key',
      area:        'Core::WebPush',
      description: 'Defines the private key used to sign web push notifications.',
      options:     {},
      state:       vapid_key.private_key,
      preferences: {
        permission: ['admin'],
        protected:  true,
      },
      frontend:    false
    )

    Setting.create_if_not_exists(
      title:       'Web Push VAPID Public Key',
      name:        'web_push_vapid_public_key',
      area:        'Core::WebPush',
      description: 'Defines the public key browsers use to subscribe to web push notifications.',
      options:     {},
      state:       vapid_key.public_key,
      preferences: {
        permission: ['admin'],
        protected:  true,
      },
      frontend:    true
    )
  end
end
