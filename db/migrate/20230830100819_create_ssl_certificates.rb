# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class CreateSSLCertificates < ActiveRecord::Migration[6.1]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    create_table :ssl_certificates do |t|
      t.string   :fingerprint,  limit: 250,          null: false
      t.binary   :certificate,  limit: 10.megabytes, null: false
      t.string   :subject,      limit: 250,          null: false
      t.datetime :not_before,   limit: 3,            null: false
      t.datetime :not_after,    limit: 3,            null: false
      t.boolean  :ca,           default: false,      null: false

      t.timestamps limit: 3, null: false
    end
  end
end
