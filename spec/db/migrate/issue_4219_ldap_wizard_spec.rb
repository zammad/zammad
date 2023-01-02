# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Issue4219LdapWizard, type: :db_migration do
  let(:ldap) { create(:ldap_source) }

  before do
    ldap.preferences['wizardData'] = { a: 1 }
    ldap.save!
    migrate
  end

  it 'does remove wizard data from ldap sources' do
    expect(ldap.reload.preferences).not_to have_key('wizardData')
  end
end
