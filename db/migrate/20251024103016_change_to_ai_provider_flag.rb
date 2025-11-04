# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class ChangeToAIProviderFlag < ActiveRecord::Migration[7.2]
  def up
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    is_provider_set = Setting.get('ai_provider').present?

    copy_provider_name
    drop_old_provider_setting
    add_new_provider_setting(is_provider_set)
  end

  private

  def copy_provider_name
    config_setting   = Setting.get('ai_provider_config')
    ai_provider_name = Setting.get('ai_provider')

    return if ai_provider_name.blank?

    config_setting[:provider] = ai_provider_name

    Setting.set('ai_provider_config', config_setting, validate: false)
  end

  def drop_old_provider_setting
    Setting
      .find_by!(name: 'ai_provider')
      .destroy!
  end

  def add_new_provider_setting(state)
    Setting.create_if_not_exists(
      title:       'AI provider',
      name:        'ai_provider',
      area:        'AI::Provider',
      description: 'Defines if the AI provider is configured.',
      options:     {},
      state:,
      preferences: {
        authentication: true,
        permission:     ['admin.ai_provider'],
      },
      frontend:    true,
    )
  end
end
