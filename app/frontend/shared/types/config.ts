export interface ConfigList {
  api_path: string
  'active_storage.web_image_content_types': string[]
  'auth_saml_credentials.display_name'?: string
  api_password_access?: boolean | null
  api_token_access?: boolean | null
  auth_facebook?: boolean | null
  auth_github?: boolean | null
  auth_gitlab?: boolean | null
  auth_google_oauth2?: boolean | null
  auth_linkedin?: boolean | null
  auth_microsoft_office365?: boolean | null
  auth_openid_connect?: boolean | null
  auth_saml?: boolean | null
  auth_sso?: boolean | null
  auth_twitter?: boolean | null
  auth_weibo?: boolean | null
  chat?: boolean | null
  chat_agent_idle_timeout: string
  checklist?: boolean | null
  core_workflow_ajax_mode?: boolean | null
  cti_integration?: boolean | null
  customer_ticket_create?: boolean | null
  customer_ticket_create_group_ids: unknown
  datepicker_show_calendar_weeks?: boolean | null
  default_controller: string
  defaults_calendar_subscriptions_tickets: unknown
  developer_mode: boolean
  exchange_integration?: boolean | null
  fqdn: string
  github_integration?: boolean | null
  gitlab_integration?: boolean | null
  http_type?: 'https' | 'http' | null
  idoit_integration?: boolean | null
  import_backend: string
  import_mode?: boolean | null
  kb_active: boolean
  kb_active_publicly: boolean
  kb_multi_lingual_support: boolean
  ldap_integration?: boolean | null
  locale_default: string
  maintenance_login: boolean
  maintenance_login_message: string
  maintenance_mode: boolean
  organization: string
  password_max_login_failed?: 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 13 | 14 | 15 | 16 | 17 | 18 | 19 | 20 | null
  pgp_config: unknown
  pgp_integration?: boolean | null
  pgp_recipient_alias_configuration: boolean
  placetel_integration?: boolean | null
  pretty_date_format: 'relative' | 'absolute' | 'timestamp'
  product_logo: string
  product_name: string
  session_timeout: unknown
  sipgate_integration?: boolean | null
  smime_config: unknown
  smime_integration?: boolean | null
  system_id?: 10 | 11 | 12 | 13 | 14 | 15 | 16 | 17 | 18 | 19 | 20 | 21 | 22 | 23 | 24 | 25 | 26 | 27 | 28 | 29 | 30 | 31 | 32 | 33 | 34 | 35 | 36 | 37 | 38 | 39 | 40 | 41 | 42 | 43 | 44 | 45 | 46 | 47 | 48 | 49 | 50 | 51 | 52 | 53 | 54 | 55 | 56 | 57 | 58 | 59 | 60 | 61 | 62 | 63 | 64 | 65 | 66 | 67 | 68 | 69 | 70 | 71 | 72 | 73 | 74 | 75 | 76 | 77 | 78 | 79 | 80 | 81 | 82 | 83 | 84 | 85 | 86 | 87 | 88 | 89 | 90 | 91 | 92 | 93 | 94 | 95 | 96 | 97 | 98 | 99 | null
  system_init_done: boolean
  system_online_service: boolean
  tag_new?: boolean | null
  ticket_agent_default_notifications: unknown
  ticket_allow_expert_conditions?: boolean | null
  ticket_auto_assignment?: boolean | null
  ticket_auto_assignment_selector: unknown
  ticket_auto_assignment_user_ids_ignore: unknown
  ticket_conditions_allow_regular_expression_operators?: boolean | null
  ticket_define_email_from?: 'SystemAddressName' | 'AgentNameSystemAddressName' | 'AgentName' | null
  ticket_define_email_from_separator: string
  ticket_duplicate_detection?: boolean | null
  ticket_duplicate_detection_attributes: unknown
  ticket_duplicate_detection_body: string
  ticket_duplicate_detection_permission_level: string
  ticket_duplicate_detection_role_ids: unknown
  ticket_duplicate_detection_search: string
  ticket_duplicate_detection_show_tickets: boolean
  ticket_duplicate_detection_title: string
  ticket_hook: string
  ticket_organization_reassignment: boolean
  ticket_secondary_action: string
  time_accounting?: boolean | null
  time_accounting_selector: unknown
  time_accounting_type_default: string
  time_accounting_types: boolean
  time_accounting_unit: string
  time_accounting_unit_custom: string
  timezone_default: string
  two_factor_authentication_enforce_role_ids: unknown
  two_factor_authentication_method_authenticator_app?: boolean | null
  two_factor_authentication_method_security_keys?: boolean | null
  two_factor_authentication_recovery_codes?: boolean | null
  ui_desktop_beta_switch: boolean
  ui_sidebar_open_ticket_indicator_colored?: boolean | null
  ui_table_group_by_show_count?: boolean | null
  ui_task_mananger_max_task_count: number
  ui_ticket_add_article_hint: unknown
  ui_ticket_create_available_types: ('phone-in' | 'phone-out' | 'email-out')[]
  ui_ticket_create_default_type: 'phone-in' | 'phone-out' | 'email-out'
  ui_ticket_create_notes: unknown
  ui_ticket_overview_query_polling: unknown
  ui_ticket_overview_ticket_limit: number
  ui_ticket_priority_icons?: boolean | null
  ui_ticket_zoom_article_delete_timeframe: number
  ui_ticket_zoom_article_email_full_quote?: boolean | null
  ui_ticket_zoom_article_email_full_quote_header?: boolean | null
  ui_ticket_zoom_article_email_subject?: boolean | null
  ui_ticket_zoom_article_note_new_internal?: boolean | null
  ui_ticket_zoom_article_twitter_initials?: boolean | null
  ui_ticket_zoom_article_visibility_confirmation_dialog?: boolean | null
  ui_ticket_zoom_attachments_preview?: boolean | null
  ui_ticket_zoom_sidebar_article_attachments?: boolean | null
  ui_user_organization_selector_with_email?: boolean | null
  user_create_account?: boolean | null
  user_lost_password?: boolean | null
  user_show_password_login?: boolean | null
  websocket_backend: string
  websocket_port: string
  [key: string]: unknown
}
