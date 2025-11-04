# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class UpdateAIPermissions < ActiveRecord::Migration[7.2]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    create_new_ai_agent_permission
    update_admin_ai_permission
    update_related_settings
  end

  private

  def create_new_ai_agent_permission
    Permission.create_if_not_exists(
      name:        'admin.ai_agent',
      label:       'AI Agents',
      description: 'Manage AI agents of your system.',
      preferences: { prio: 1336 }
    )
  end

  def update_admin_ai_permission
    Permission.create_or_update(
      name:        'admin.ai_provider',
      label:       'AI Provider',
      description: 'Manage AI provider of your system.',
      preferences: { prio: 1333 }
    )
  end

  def update_related_settings
    %w[ai_provider ai_provider_config].each do |setting_name|
      setting = Setting.find_by(name: setting_name)
      next if !setting

      setting.preferences[:permission] = ['admin.ai_provider']

      setting.save!(validate: false)
    end
  end
end
