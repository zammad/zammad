require 'rails_helper'

RSpec.describe MigrationJob::LdapSamaccountnameToUid do

  it 'performs no changes if no LDAP config present' do
    allow(Setting).to receive(:set)
    allow(Import::Ldap).to receive(:config).and_return(nil)

    described_class.new.perform
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

    described_class.new.perform
    expect(Setting).not_to have_received(:set)
  end

  it 'performs Setting change if uid attribute differ' do
    ldap_config_new = {
      'user_uid' => 'objectguid'
    }
    ldap_config_obsolete = {
      'user_uid' => 'samaccountname'
    }

    allow(Setting).to receive(:set)

    allow(Import::Ldap).to receive(:config).and_return(ldap_config_obsolete)

    ldap_user = double()
    allow(ldap_user).to receive(:uid_attribute).and_return('objectguid')
    allow(::Ldap::User).to receive(:new).and_return(ldap_user)

    allow(::Ldap).to receive(:new)

    described_class.new.perform

    expect(Setting).to have_received(:set).with('ldap_config', ldap_config_new)
  end
end
