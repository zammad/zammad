# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Issue5863FormSpamProtectionSettings < ActiveRecord::Migration[8.0]
  def up
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.create_if_not_exists(
      title:       'Honeypot spam protection',
      name:        'form_ticket_create_honeypot',
      area:        'Form::SpamProtection',
      description: 'Adds an invisible field to the web form and rejects submissions that fill it in, which automated clients tend to do.',
      options:     {
        form: [
          {
            display: '',
            null:    true,
            name:    'form_ticket_create_honeypot',
            tag:     'boolean',
            options: {
              true  => 'yes',
              false => 'no',
            },
          },
        ],
      },
      state:       true,
      preferences: {
        permission: ['admin.channel_formular'],
      },
      frontend:    false,
    )

    Setting.create_if_not_exists(
      title:       'CAPTCHA provider',
      name:        'form_ticket_create_captcha_provider',
      area:        'Form::SpamProtection',
      description: 'Defines the CAPTCHA provider used to protect the web form. Leave empty to disable. The list of available providers is derived from the registered FormSpamProtection::Captcha backends.',
      state:       '',
      preferences: {
        permission: ['admin.channel_formular'],
      },
      frontend:    false,
    )

    Setting.create_if_not_exists(
      title:       'CAPTCHA provider options',
      name:        'form_ticket_create_captcha_options',
      area:        'Form::SpamProtection',
      description: 'Stores the credentials (e.g. site key and secret) of the selected CAPTCHA provider.',
      state:       {},
      preferences: {
        permission: ['admin.channel_formular'],
      },
      frontend:    false,
    )
  end
end
