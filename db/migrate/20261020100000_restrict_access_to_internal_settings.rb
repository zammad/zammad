# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class RestrictAccessToInternalSettings < ActiveRecord::Migration[8.0]
  PERMISSIONS = {
    'session_timeout'                               => 'admin.security',
    'language_detection_article'                    => 'admin.ticket',
    'ui_desktop_beta_switch'                        => 'admin.beta_ui',
    'ui_desktop_beta_switch_role_ids'               => 'admin.beta_ui',
    'vectordb_enabled'                              => 'admin.ai_knowledge_base',
    'vectordb_knowledge_base_excluded_category_ids' => 'admin.ai_knowledge_base',
    'vectordb_knowledge_base_chunking_strategy'     => 'admin.ai_knowledge_base',
  }.freeze

  ADMIN_ONLY = %w[
    pgp_recipient_alias_configuration
    defaults_calendar_subscriptions_tickets
    system_bcc
    form_allowed_params
    system_init_done
    app_version
    developer_mode
    system_online_service
    websocket_backend
    websocket_port
    default_controller
    es_url
    es_user
    es_password
    es_index
    es_ssl_verify
    es_attachment_ignore
    es_attachment_max_size_in_mb
    es_total_max_size_in_mb
    es_pipeline
    es_model_settings
    es_asciifolding
    import_mode
    import_backend
    import_ignore_sla
    import_otrs_endpoint
    import_otrs_endpoint_key
    import_otrs_user
    import_otrs_password
    import_zendesk_endpoint
    import_zendesk_endpoint_key
    import_zendesk_endpoint_username
    import_freshdesk_endpoint
    import_freshdesk_endpoint_key
    import_kayako_endpoint
    import_kayako_endpoint_username
    import_kayako_endpoint_password
    sequencer_log_level
    0000_postmaster_filter_trusted
    0006_postmaster_filter_auto_response_check
    0007_postmaster_filter_follow_up_check
    0008_postmaster_filter_follow_up_merged
    0010_postmaster_filter_follow_up_assignment
    0011_postmaster_sender_based_on_reply_to
    0018_postmaster_import_archive
    6105_postmaster_filter_sender_is_system_address
    0014_postmaster_filter_own_notification_loop_detection
    0015_postmaster_filter_identify_session_user
    6500_postmaster_filter_identify_sender
    0001_postmaster_filter_secure_mailing
    0012_postmaster_filter_attachment_reference_remove
    0009_postmaster_filter_out_of_office_check
    0200_postmaster_filter_follow_up_possible_check
    0900_postmaster_filter_bounce_follow_up_check
    0950_postmaster_filter_bounce_delivery_permanent_failed
    0955_postmaster_filter_bounce_delivery_temporary_failed
    1000_postmaster_filter_database_check
    5000_postmaster_filter_icinga
    5100_postmaster_filter_nagios
    5200_postmaster_filter_check_mk
    5300_postmaster_filter_monit
    5400_postmaster_filter_service_now_check
    5401_postmaster_filter_service_now_check
    5400_postmaster_filter_jira_check
    5401_postmaster_filter_jira_check
    5500_postmaster_internal_article_check
    6005_postmaster_filter_identify_group
    0100_trigger
    0100_notification
    1000_signature_detection
    9000_clearbit_enrichment
    9100_cti_caller_id_detection
    9200_time_based_trigger
    system_agent_limit
    html_sanitizer_processing_timeout
    kb_multi_lingual_support
    auto_shutdown
    ui_desktop_beta_switch_admin_menu
    vectordb_indexed_embedding_configuration
  ].freeze

  PROTECTED = %w[
    kb_active_publicly
  ].freeze

  def change
    return if !Setting.exists?(name: 'system_init_done')

    PERMISSIONS.each { |name, permission| update_preferences(name, permission: [permission]) }
    ADMIN_ONLY.each { |name| update_preferences(name, permission: ['admin']) }
    PROTECTED.each { |name| update_preferences(name, permission: ['admin'], protected: true) }
  end

  private

  def update_preferences(name, preferences)
    setting = Setting.find_by(name: name)
    return if !setting

    preferences.each { |key, value| setting.preferences[key] = value }
    setting.skip_validate = true
    setting.save!
  end
end
