# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class CreateAIProviderConnections < ActiveRecord::Migration[8.0]
  def up
    # return if it's a new setup (fresh installs get these tables from CreateBase)
    return if !Setting.exists?(name: 'system_init_done')

    create_admin_ai_feedback_logs_permission
    create_provider_connections_table
    create_feature_providers_table
    migrate_existing_provider
    migrate_ticket_summarize_config
    drop_provider_config_setting
  end

  private

  def create_admin_ai_feedback_logs_permission
    Permission.create_or_update(
      name:        'admin.ai_feedback_logs',
      label:       'AI Feedback & Logs',
      description: 'Manage AI feedback and logs of your system.',
      preferences: { prio: 1338 }
    )
  end

  def create_provider_connections_table
    create_table :ai_provider_connections, id: :integer, if_not_exists: true do |t|
      t.string  :name,              limit: 250, null: false
      t.string  :provider,          limit: 250, null: false
      t.jsonb   :config,                        null: false, default: {}
      t.boolean :default_chat,                  null: false, default: false
      t.boolean :default_embedding,             null: false, default: false
      t.boolean :default_ocr,                   null: false, default: false
      t.jsonb   :status,                        null: false, default: {}

      t.timestamps limit: 3

      t.index :name, unique: true
      t.index :default_chat
      t.index :default_embedding
      t.index :default_ocr
    end

    AI::ProviderConnection.reset_column_information
  end

  def create_feature_providers_table
    create_table :ai_feature_providers, id: :integer, if_not_exists: true do |t|
      t.string :identifier, null: false

      t.references :provider_connection, null: false, foreign_key: { to_table: :ai_provider_connections }, type: :integer

      t.jsonb :options, null: false, default: {}

      t.timestamps limit: 3

      t.index :identifier, unique: true
    end

    AI::FeatureProvider.reset_column_information
  end

  # Converts the current single-provider setup into the `default` connection (idempotent; no
  # routing rows seeded — for_chat falls back to the chat default, and so do the embedding
  # and OCR resolutions). Validation is skipped: the existing config is already valid, and on
  # SaaS this migration IS the zammad_ai provisioning path that the admin API itself refuses.
  def migrate_existing_provider
    provider = legacy_provider_config[:provider]
    return if provider.blank? || AI::ProviderConnection.exists?(name: provider)

    connection = AI::ProviderConnection.new(
      name:              provider,
      provider:          provider,
      config:            legacy_provider_config.except(:provider).to_h,
      default_chat:      true,
      default_embedding: true,
      default_ocr:       true,
    )
    connection.save!(validate: false)
  end

  # Carries the OCR flag of the dropped provider config over to the summary options. Merged into
  # the stored values instead of assigned: re-seeding does not touch an existing setting, so this
  # is the only way the new key reaches an upgraded system - without pinning a copy of the seed
  # defaults, which would go stale as soon as one of them changes.
  def migrate_ticket_summarize_config
    setting = Setting.find_by(name: 'ai_assistance_ticket_summary_config')
    return if setting.nil?

    ocr_active = legacy_provider_config[:provider].present? &&
                 ActiveModel::Type::Boolean.new.cast(legacy_provider_config[:ocr_active]) == true

    setting.state_initial = { value: { **setting.state_initial[:value], ocr_active: false } }
    setting.state_current = { value: { **setting.state_current[:value], ocr_active: } }
    setting.save!
  end

  # The provider config as it was stored before connections existed; dropped at the end of the run.
  def legacy_provider_config
    @legacy_provider_config ||= Setting.get('ai_provider_config').presence&.with_indifferent_access || {}
  end

  def drop_provider_config_setting
    Setting.find_by(name: 'ai_provider_config')&.destroy!
  end
end
