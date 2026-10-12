# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Issue3934LdapMultiUserAttributeMapping, type: :db_migration do

  let!(:ldap_source) { create(:ldap_source, preferences: preferences) }

  context 'with a legacy single attribute mapping' do
    let(:preferences) do
      {
        'user_uid'        => 'uid',
        'user_attributes' => { 'cn' => 'firstname', 'uid' => 'login' },
      }
    end

    it 'converts the mapping values to arrays' do
      migrate
      ldap_source.reload

      expect(ldap_source.preferences['user_attributes']).to eq(
        { 'cn' => ['firstname'], 'uid' => ['login'] }
      )
    end
  end

  context 'with an already converted mapping' do
    let(:preferences) do
      {
        'user_attributes' => { 'mail' => %w[login email] },
      }
    end

    it 'keeps the mapping unchanged' do
      migrate
      ldap_source.reload

      expect(ldap_source.preferences['user_attributes']).to eq(
        { 'mail' => %w[login email] }
      )
    end
  end

  context 'with a partially converted mapping' do
    let(:preferences) do
      {
        'user_attributes' => { 'mail' => %w[login email], 'cn' => 'firstname' },
      }
    end

    it 'converts only the remaining single values' do
      migrate
      ldap_source.reload

      expect(ldap_source.preferences['user_attributes']).to eq(
        { 'mail' => %w[login email], 'cn' => ['firstname'] }
      )
    end
  end

  context 'without a user attribute mapping' do
    let(:preferences) do
      {
        'user_uid' => 'uid',
      }
    end

    it 'does not fail' do
      expect { migrate }.not_to raise_error
    end
  end
end
