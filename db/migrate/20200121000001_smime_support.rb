# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class SMIMESupport < ActiveRecord::Migration[5.2]
  def up

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.create_if_not_exists(
      title:       'S/MIME integration',
      name:        'smime_integration',
      area:        'Integration::Switch',
      description: 'Defines if S/MIME encryption is enabled or not.',
      options:     {
        form: [
          {
            display: '',
            null:    true,
            name:    'smime_integration',
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
      title:       'S/MIME config',
      name:        'smime_config',
      area:        'Integration::SMIME',
      description: 'Defines the S/MIME config.',
      options:     {},
      state:       {},
      preferences: {
        prio:       2,
        permission: ['admin.integration'],
      },
      frontend:    true,
    )
    Setting.create_if_not_exists(
      title:       'Defines postmaster filter.',
      name:        '0016_postmaster_filter_smime',
      area:        'Postmaster::PreFilter',
      description: 'Defines postmaster filter to handle secure mailing.',
      options:     {},
      state:       'Channel::Filter::SecureMailing',
      frontend:    false
    )

    create_table :smime_certificates do |t|
      t.string :subject,            limit: 500,  null: false
      t.string :doc_hash,           limit: 250,  null: false
      t.string :fingerprint,        limit: 250,  null: false
      t.string :modulus,            limit: 1024, null: false
      t.datetime :not_before_at,                 null: true # rubocop:disable Zammad/ExistsDateTimePrecision
      t.datetime :not_after_at,                  null: true # rubocop:disable Zammad/ExistsDateTimePrecision
      t.binary :raw,                limit: 10.megabytes,  null: false
      t.binary :private_key,        limit: 10.megabytes,  null: true
      t.string :private_key_secret, limit: 500, null: true
      t.timestamps limit: 3, null: false
    end
    add_index :smime_certificates, [:fingerprint], unique: true
    add_index :smime_certificates, [:modulus]
    add_index :smime_certificates, [:subject]
  end

end
