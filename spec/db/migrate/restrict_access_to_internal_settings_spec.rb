# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe RestrictAccessToInternalSettings, type: :db_migration do
  def reset_preferences(name, preferences)
    Setting.find_by(name:).tap do |setting|
      setting.preferences = preferences
      setting.save!
    end
  end

  it 'adds the permission of the admin page that changes a setting', :aggregate_failures do
    session_timeout  = reset_preferences('session_timeout', { prio: 30 })
    vectordb_enabled = reset_preferences('vectordb_enabled', { authentication: true })

    migrate

    expect(session_timeout.reload.preferences).to include(prio: 30, permission: ['admin.security'])
    expect(vectordb_enabled.reload.preferences).to include(authentication: true, permission: ['admin.ai_knowledge_base'])
  end

  it 'restricts other settings to full admins', :aggregate_failures do
    developer_mode = reset_preferences('developer_mode', { online_service_disable: true })
    system_bcc     = reset_preferences('system_bcc', { online_service_disable: true })

    migrate

    expect(developer_mode.reload.preferences).to include(online_service_disable: true, permission: ['admin'])
    expect(developer_mode.preferences).not_to include(:protected)
    expect(system_bcc.reload.preferences).to include(online_service_disable: true, permission: ['admin'])
  end

  it 'protects the public knowledge base state' do
    kb_active_publicly = reset_preferences('kb_active_publicly', { authentication: true, permission: [] })

    migrate

    expect(kb_active_publicly.reload.preferences).to include(authentication: true, permission: ['admin'], protected: true)
  end
end
