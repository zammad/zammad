# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class PGPIntegration < ActiveRecord::Migration[6.1]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    create_pgp_keys_table
    create_pgp_keys_table_indices
    create_pgp_keys_table_foreign_keys
    create_pgp_integration_settings

    rename_postmaster_pre_filter
  end

  private

  def create_pgp_keys_table
    create_table :pgp_keys do |t|
      t.string   :fingerprint, limit: 40, null: false
      t.text     :key,         limit: 500.kilobytes + 1, null: false
      t.datetime :expires_at, null: true, limit: 3
      t.string   :uids, limit: 3000, null: false
      t.boolean  :secret, null: false, default: false
      t.string   :passphrase, limit: 500, null: true
      t.string   :domain_alias, limit: 255, null: true, default: ''
      t.integer  :updated_by_id,            null: false
      t.integer  :created_by_id,            null: false
      t.timestamps limit: 3, null: false
    end
  end

  def create_pgp_keys_table_indices
    add_index :pgp_keys, [:fingerprint], unique: true
    add_index :pgp_keys, [:uids], length: 255
    add_index :pgp_keys, [:domain_alias]
  end

  def create_pgp_keys_table_foreign_keys
    add_foreign_key :pgp_keys, :users, column: :created_by_id
    add_foreign_key :pgp_keys, :users, column: :updated_by_id
  end

  def create_pgp_integration_settings
    Setting.create_if_not_exists(
      title:       'PGP integration',
      name:        'pgp_integration',
      area:        'Integration::Switch',
      description: 'Defines if PGP encryption is enabled or not.',
      options:     {
        form: [
          {
            display: '',
            null:    true,
            name:    'pgp_integration',
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
      title:       'PGP config',
      name:        'pgp_config',
      area:        'Integration::PGP',
      description: 'Defines the PGP config.',
      options:     {},
      state:       {},
      preferences: {
        prio:       2,
        permission: ['admin.integration'],
      },
      frontend:    true,
    )

    Setting.create_if_not_exists(
      title:       'PGP Recipient Alias Configuration',
      name:        'pgp_recipient_alias_configuration',
      area:        'Core::Integration::PGP',
      description: 'Defines if the PGP recipient alias configuration is enabled or not.',
      options:     {},
      state:       false,
      preferences: { online_service_disable: true },
      frontend:    true
    )
  end

  def rename_postmaster_pre_filter
    Setting.find_by(name: '0016_postmaster_filter_smime').update!(name: '0016_postmaster_filter_secure_mailing')
  end
end
