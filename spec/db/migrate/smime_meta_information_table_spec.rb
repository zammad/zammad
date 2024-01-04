# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe SMIMEMetaInformationTable, db_strategy: :reset, type: :db_migration do
  describe 'migrate SQL table' do
    before do
      ActiveRecord::Migration[6.1].drop_table :smime_certificates

      ActiveRecord::Migration[6.1].create_table :smime_certificates do |t|
        t.string :subject,            limit: 500,  null: false
        t.string :doc_hash,           limit: 250,  null: false
        t.string :fingerprint,        limit: 250,  null: false
        t.string :modulus,            limit: 1024, null: false
        t.datetime :not_before_at,                 null: true, limit: 3
        t.datetime :not_after_at,                  null: true, limit: 3
        t.binary :raw,                limit: 10.megabytes,  null: false
        t.binary :private_key,        limit: 10.megabytes,  null: true
        t.string :private_key_secret, limit: 500, null: true
        t.timestamps limit: 3, null: false
      end
      ActiveRecord::Migration[6.1].add_index :smime_certificates, [:fingerprint], unique: true
      ActiveRecord::Migration[6.1].add_index :smime_certificates, [:modulus]
      ActiveRecord::Migration[6.1].add_index :smime_certificates, [:subject]
    end

    it 'does change the table structur' do
      migrate
      expect(SMIMECertificate.column_names).to include('email_addresses')
    end
  end
end
