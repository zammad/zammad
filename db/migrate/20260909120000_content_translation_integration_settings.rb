# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class ContentTranslationIntegrationSettings < ActiveRecord::Migration[8.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    add_service_setting
    add_service_config_setting
    add_ticket_article_setting
    add_ticket_article_auto_setting
    add_ticket_article_auto_role_ids_setting
  end

  private

  def add_service_setting
    Setting.create_if_not_exists(
      title:       'Translation Service',
      name:        'content_translation_service',
      area:        'Integration::Translation',
      description: 'Defines if a translation service is configured.',
      options:     {},
      state:       false,
      preferences: {
        authentication: true,
        permission:     ['admin.integration'],
        validations:    ['Setting::Validation::ContentTranslationService'],
      },
      frontend:    true,
    )
  end

  # Holds the provider and its credentials, so it must never be delivered to the frontend:
  # frontend settings are read raw by the session config and by Gql::Queries::ApplicationConfig,
  # where the masking of SettingsController does not apply.
  def add_service_config_setting
    Setting.create_if_not_exists(
      title:       'Translation Service Config',
      name:        'content_translation_service_config',
      area:        'Integration::Translation',
      description: 'Stores the translation service configuration.',
      options:     {},
      state:       {},
      preferences: {
        authentication: true,
        permission:     ['admin.integration'],
        validations:    ['Setting::Validation::ContentTranslationServiceConfig'],
      },
      frontend:    false,
    )
  end

  def add_ticket_article_setting
    Setting.create_if_not_exists(
      title:       'Article Translation',
      name:        'content_translation_ticket_article',
      area:        'Integration::Translation::TicketArticle',
      description: 'Enable or disable the translation of ticket articles.',
      options:     {},
      state:       false,
      preferences: {
        authentication: true,
        permission:     ['admin.integration'],
      },
      frontend:    true,
    )
  end

  def add_ticket_article_auto_setting
    Setting.create_if_not_exists(
      title:       'Automatic Article Translation',
      name:        'content_translation_ticket_article_auto',
      area:        'Integration::Translation::TicketArticle',
      description: 'Enable or disable the automatic translation of ticket articles when an agent opens a ticket.',
      options:     {},
      state:       false,
      preferences: {
        authentication: true,
        permission:     ['admin.integration'],
      },
      frontend:    true,
    )
  end

  def add_ticket_article_auto_role_ids_setting
    Setting.create_if_not_exists(
      title:       'Automatic Article Translation Roles',
      name:        'content_translation_ticket_article_auto_role_ids',
      area:        'Integration::Translation::TicketArticle',
      description: 'Defines which user roles automatic article translation applies to.',
      options:     {},
      state:       [],
      preferences: {
        authentication: true,
        permission:     ['admin.integration'],
      },
      frontend:    false,
    )
  end
end
