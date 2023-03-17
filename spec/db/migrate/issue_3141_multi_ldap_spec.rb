# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Issue3141MultiLdap, type: :db_migration do
  let(:ldap_user) { create(:user, source: 'Ldap') }

  before do
    ldap_user

    Setting.create_or_update(
      title:       __('LDAP config'),
      name:        'ldap_config',
      area:        'Integration::LDAP',
      description: __('Defines the LDAP config.'),
      options:     {},
      state:       { filled: true },
      preferences: {
        prio:       2,
        permission: ['admin.integration'],
      },
      frontend:    false,
    )

    migrate do |migration|
      allow(migration).to receive(:add_table)
    end
  end

  it 'does create ldap source' do
    expect(LdapSource.first.preferences).to eq({ 'filled' => true })
  end

  it 'does remove the setting' do
    expect(Setting.find_by(name: 'ldap_config')).to be_nil
  end

  it 'does migrate source of all users' do
    expect(ldap_user.reload.source).to eq("Ldap::#{LdapSource.first.id}")
  end
end
