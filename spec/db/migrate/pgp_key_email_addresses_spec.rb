# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe PGPKeyEmailAddresses, db_strategy: :reset, type: :db_migration do
  before do
    add_column :pgp_keys, :uids, :string, limit: 3000, null: false, default: ''
    add_index :pgp_keys, [:uids], length: 255
    without_column :pgp_keys, column: :name
    without_column :pgp_keys, column: :email_addresses

    PGPKey.reset_column_information

    migrate
  end

  it 'adds `name` column' do
    expect(column_exists?(:pgp_keys, :name)).to be(true)
  end

  it 'adds `email_addresses` column' do
    expect(column_exists?(:pgp_keys, :email_addresses)).to be(true)
  end

  it 'removes `uids` column' do
    expect(column_exists?(:pgp_keys, :uids)).to be(false)
  end
end
