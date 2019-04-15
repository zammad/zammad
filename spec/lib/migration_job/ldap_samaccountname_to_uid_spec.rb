require 'rails_helper'

RSpec.describe MigrationJob::LdapSamaccountnameToUid do

  it 'performs no changes if no LDAP config present' do
    expect(Setting).not_to receive(:set)
    expect(Import::Ldap).to receive(:config).and_return(nil)

    described_class.new.perform
  end

  it 'performs no changes if uid attributes equals' do
    expect(Setting).not_to receive(:set)

    ldap_config = {
      'user_uid' => 'samaccountname'
    }
    expect(Import::Ldap).to receive(:config).and_return(ldap_config)

    ldap_user = double()
    expect(ldap_user).to receive(:uid_attribute).and_return('samaccountname')
    expect(::Ldap::User).to receive(:new).and_return(ldap_user)

    allow(::Ldap).to receive(:new)

    described_class.new.perform
  end

  it 'performs Setting change if uid attribute differ' do
    ldap_config_new = {
      'user_uid' => 'objectguid'
    }
    ldap_config_obsolete = {
      'user_uid' => 'samaccountname'
    }

    expect(Setting).to receive(:set).with('ldap_config', ldap_config_new)

    expect(Import::Ldap).to receive(:config).and_return(ldap_config_obsolete)

    ldap_user = double()
    expect(ldap_user).to receive(:uid_attribute).and_return('objectguid')
    expect(::Ldap::User).to receive(:new).and_return(ldap_user)

    allow(::Ldap).to receive(:new)

    described_class.new.perform
  end
end
