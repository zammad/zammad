# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe LdapSamaccountnameToUid, type: :db_migration do
  let(:target_user_id) { 'new_user_id' }
  let(:ldap_source)    { create(:ldap_source, preferences: { 'user_uid' => current_user_id }.compact) }

  before do
    ldap_user = double
    allow(ldap_user).to receive(:uid_attribute).and_return(target_user_id)
    allow(Ldap::User).to receive(:new).and_return(ldap_user)

    allow(Ldap).to receive(:new)

    ldap_source
  end

  context 'when uid attributes equals' do
    let(:current_user_id) { target_user_id }

    it 'performs no changes' do
      expect { migrate }.not_to change { ldap_source.reload.preferences }
    end
  end

  context 'when uid attributes differ' do
    let(:current_user_id) { 'old_user_id' }

    it 'migrates user_uid' do
      expect { migrate }
        .to change { ldap_source.reload.preferences['user_uid'] }
        .from(current_user_id)
        .to(target_user_id)
    end
  end

  context 'when no uid in preferences' do
    let(:current_user_id) { nil }

    it 'performs no changes' do
      expect { migrate }.not_to change { ldap_source.reload.preferences }
    end
  end
end
