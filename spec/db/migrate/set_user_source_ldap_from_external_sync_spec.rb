# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe SetUserSourceLdapFromExternalSync, db_strategy: :reset, type: :db_migration do
  let(:users)      { create_list(:user, 2) }
  let(:other_user) { create(:user) }

  before do
    2.times do |count|
      index = count - 1

      create(:external_sync,
             source:    'Ldap::User',
             source_id: "uid=#{users[index].login},ou=People,dc=example,dc=org",
             object:    'User',
             o_id:      users[index].id)
    end
  end

  context 'when having users from the ldap integration' do
    it 'source key for users are filled' do
      expect { migrate }.to change { users[0].reload.source }.to('Ldap').and change { users[1].reload.source }.to('Ldap')
    end

    it 'other user should not be touched' do
      expect { migrate }.not_to change { other_user.reload.source }
    end
  end
end
