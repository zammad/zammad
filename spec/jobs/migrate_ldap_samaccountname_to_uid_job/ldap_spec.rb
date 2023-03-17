# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe MigrateLdapSamaccountnameToUidJob::Ldap, type: :job do
  it 'performs no changes if uid attributes equals' do
    ldap_user = double

    allow(ldap_user).to receive(:uid_attribute).and_return('samaccountname')
    allow(Ldap::User).to receive(:new).and_return(ldap_user)

    allow(Ldap).to receive(:new)

    described_class.new(create(:ldap_source, preferences: { 'user_uid' => 'samaccountname' })).perform

    expect(ldap_user).to have_received(:uid_attribute)
    expect(Ldap::User).to have_received(:new)
  end

  it 'performs Setting change if uid attribute differ' do
    ldap_user = double
    allow(ldap_user).to receive(:uid_attribute).and_return('objectguid')
    allow(Ldap::User).to receive(:new).and_return(ldap_user)

    ldap_source = create(:ldap_source, preferences: { 'user_uid' => 'samaccountname' })

    allow(Ldap).to receive(:new)

    described_class.new(ldap_source).perform

    expect(ldap_user).to have_received(:uid_attribute)
    expect(ldap_source.preferences['user_uid']).to eq('objectguid')
  end
end
