# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe MigrateLdapSamaccountnameToUidJob, type: :job do

  it 'performs no changes if no LDAP config present' do
    allow(Setting).to receive(:set)
    allow(Import::Ldap).to receive(:config).and_return(nil)

    described_class.perform_now

    expect(Import::Ldap).to have_received(:config)
    expect(Setting).not_to have_received(:set)
  end

  it 'performs no changes if uid attributes equals' do
    allow(Setting).to receive(:set)

    ldap_config = {
      'user_uid' => 'samaccountname'
    }
    allow(Import::Ldap).to receive(:config).and_return(ldap_config)

    ldap_user = double()
    allow(ldap_user).to receive(:uid_attribute).and_return('samaccountname')
    allow(::Ldap::User).to receive(:new).and_return(ldap_user)

    allow(::Ldap).to receive(:new)

    described_class.perform_now

    expect(Setting).not_to have_received(:set)
    expect(Import::Ldap).to have_received(:config)
    expect(ldap_user).to have_received(:uid_attribute)
    expect(::Ldap::User).to have_received(:new)
  end

  it 'performs Setting change if uid attribute differ' do
    ldap_config_new = {
      'user_uid' => 'objectguid'
    }
    ldap_config_obsolete = {
      'user_uid' => 'samaccountname'
    }

    allow(Setting).to receive(:set)
    allow(Setting).to receive(:set).with('ldap_config', ldap_config_new)

    allow(Import::Ldap).to receive(:config).and_return(ldap_config_obsolete)

    ldap_user = double()
    allow(ldap_user).to receive(:uid_attribute).and_return('objectguid')
    allow(::Ldap::User).to receive(:new).and_return(ldap_user)

    allow(::Ldap).to receive(:new)

    described_class.perform_now

    expect(Setting).to have_received(:set).with('ldap_config', ldap_config_new)
    expect(ldap_user).to have_received(:uid_attribute)
  end
end
