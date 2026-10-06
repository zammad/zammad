# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe AddAlternativeFqdnSetting, db_strategy: :reset, type: :db_migration do
  before do
    Setting.find_by(name: 'alternative_fqdn')&.destroy!
  end

  it 'creates the alternative FQDN setting' do
    expect { migrate }
      .to change { Setting.exists?(name: 'alternative_fqdn') }
      .to(true)
  end

  it 'restricts changes to system administrators outside of the hosted service' do
    migrate

    expect(Setting.find_by(name: 'alternative_fqdn').preferences).to include(online_service_disable: true, permission: ['admin.system'])
  end
end
