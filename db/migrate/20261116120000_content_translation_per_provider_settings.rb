# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class ContentTranslationPerProviderSettings < ActiveRecord::Migration[8.1]
  SHARED_SETTINGS = %w[
    content_translation_service
    content_translation_ticket_article
    content_translation_ticket_article_auto
    content_translation_ticket_article_auto_role_ids
  ].freeze

  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    add_permission
    remove_service_config
    add_provider_setting
    add_deepl_config_setting
    add_libre_translate_config_setting
    share_settings_with_ai_translation
  end

  private

  def add_permission
    Permission.create_if_not_exists(
      name:        'admin.ai_assistance_translation',
      label:       'AI Translation',
      description: 'Manage AI translation of your system.',
      preferences: { prio: 1337 }
    )
  end

  # The configuration is not carried over: the feature was never released. The flag goes off with
  # it, as it would otherwise offer agents a translation that no provider can run.
  def remove_service_config
    Setting.set('content_translation_service', false) if Setting.exists?(name: 'content_translation_service')
    Setting.find_by(name: 'content_translation_service_config')&.destroy
  end

  def add_provider_setting
    Setting.create_if_not_exists(
      title:       'Translation Provider',
      name:        'content_translation_provider',
      area:        'Integration::Translation',
      description: 'Defines which translation provider is active.',
      options:     {},
      state:       '',
      preferences: {
        authentication: true,
        permission:     ['admin.integration', 'admin.ai_assistance_translation'],
        validations:    ['Setting::Validation::ContentTranslationProvider'],
      },
      frontend:    false,
    )
  end

  def add_deepl_config_setting
    Setting.create_if_not_exists(
      title:       'DeepL Config',
      name:        'content_translation_deepl_config',
      area:        'Integration::Translation',
      description: 'Stores the DeepL configuration.',
      options:     {},
      state:       {},
      preferences: {
        authentication: true,
        permission:     ['admin.integration'],
        validations:    ['Setting::Validation::ContentTranslationDeepLConfig'],
      },
      frontend:    false,
    )
  end

  def add_libre_translate_config_setting
    Setting.create_if_not_exists(
      title:       'LibreTranslate Config',
      name:        'content_translation_libre_translate_config',
      area:        'Integration::Translation',
      description: 'Stores the LibreTranslate configuration.',
      options:     {},
      state:       {},
      preferences: {
        authentication: true,
        permission:     ['admin.integration'],
        validations:    ['Setting::Validation::ContentTranslationLibreTranslateConfig'],
      },
      frontend:    false,
    )
  end

  def share_settings_with_ai_translation
    Setting.where(name: SHARED_SETTINGS).find_each do |setting|
      setting.preferences[:permission] = ['admin.integration', 'admin.ai_assistance_translation']
      setting.save!
    end
  end
end
