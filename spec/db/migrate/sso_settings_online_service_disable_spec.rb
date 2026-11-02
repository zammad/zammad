# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe SsoSettingsOnlineServiceDisable, type: :db_migration do
  before do
    %w[auth_sso auth_sso_trusted_ips].each do |name|
      setting = Setting.find_by(name: name)
      setting.preferences.delete(:online_service_disable)
      setting.save!
    end
  end

  it 'disables the SSO settings for the online service', :aggregate_failures do
    migrate

    expect(Setting.find_by(name: 'auth_sso').preferences).to include(online_service_disable: true, permission: ['admin.security'])
    expect(Setting.find_by(name: 'auth_sso_trusted_ips').preferences).to include(online_service_disable: true, permission: ['admin.security'])
  end
end
