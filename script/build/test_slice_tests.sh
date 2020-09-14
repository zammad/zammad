#!/bin/bash
LEVEL=$1

set -ex

if [ "$LEVEL" == '1' ]; then
  echo "slicing level 1"

  # no ticket action
  rm test/browser/aaa_getting_started_test.rb
  cp contrib/auto_wizard_test.json auto_wizard.json
  cp test/integration/aaa_auto_wizard_base_setup_test.rb test/browser/aaa_auto_wizard_base_setup_test.rb
  rm test/browser/abb_one_group_test.rb
  rm test/browser/admin_channel_email_test.rb
  rm test/browser/admin_calendar_sla_test.rb
  rm test/browser/admin_drag_drop_to_new_group_test.rb
  rm test/browser/admin_object_manager_test.rb
  rm test/browser/admin_object_manager_tree_select_test.rb
  rm test/browser/admin_overview_test.rb
  rm test/browser/admin_permissions_granular_vs_full_test.rb
  rm test/browser/admin_role_test.rb
  # test/browser/agent_navigation_and_title_test.rb
  # test/browser/agent_organization_profile_test.rb
  rm test/browser/agent_ticket_attachment_test.rb
  rm test/browser/agent_ticket_create_available_types_test.rb
  rm test/browser/agent_ticket_create_attachment_missing_after_reload_test.rb
  rm test/browser/agent_ticket_create_cc_tokenizer_test.rb
  rm test/browser/agent_ticket_create_default_type_test.rb
  rm test/browser/agent_ticket_create_reset_customer_selection_test.rb
  rm test/browser/agent_ticket_create_template_test.rb
  rm test/browser/agent_ticket_email_reply_keep_body_test.rb
  rm test/browser/agent_ticket_email_signature_test.rb
  rm test/browser/agent_ticket_link_test.rb
  rm test/browser/agent_ticket_macro_test.rb
  rm test/browser/agent_ticket_merge_test.rb
  rm test/browser/agent_ticket_online_notification_test.rb
  rm test/browser/agent_ticket_overview_group_by_organization_test.rb
  rm test/browser/agent_ticket_overview_level0_test.rb
  rm test/browser/agent_ticket_overview_level1_test.rb
  rm test/browser/agent_ticket_overview_pending_til_test.rb
  rm test/browser/agent_ticket_overview_tab_test.rb
  rm test/browser/agent_ticket_tag_test.rb
  rm test/browser/agent_ticket_task_changed_test.rb
  rm test/browser/agent_ticket_text_module_test.rb
  rm test/browser/agent_ticket_time_accounting_test.rb
  rm test/browser/agent_ticket_update1_test.rb
  rm test/browser/agent_ticket_update2_test.rb
  rm test/browser/agent_ticket_update3_test.rb
  rm test/browser/agent_ticket_update4_test.rb
  rm test/browser/agent_ticket_update5_test.rb
  rm test/browser/agent_ticket_update_with_attachment_refresh_test.rb
  rm test/browser/agent_ticket_update_and_reload_test.rb
  rm test/browser/agent_ticket_zoom_hide_test.rb
  rm test/browser/agent_user_manage_test.rb
  rm test/browser/agent_user_profile_test.rb
  # test/browser/auth_test.rb
  rm test/browser/chat_test.rb
  rm test/browser/chat_no_jquery_test.rb
  rm test/browser/customer_ticket_create_fields_test.rb
  rm test/browser/customer_ticket_create_test.rb
  rm test/browser/first_steps_test.rb
  # test/browser/form_test.rb
  rm test/browser/integration_test.rb
  rm test/browser/keyboard_shortcuts_test.rb
  # test/browser/maintenance_app_version_test.rb
  # test/browser/maintenance_mode_test.rb
  # test/browser/maintenance_session_message_test.rb
  # test/browser/manage_test.rb
  # test/browser/monitoring_test.rb
  rm test/browser/integration_sipgate_test.rb
  rm test/browser/integration_cti_test.rb
  rm test/browser/preferences_language_test.rb
  rm test/browser/preferences_permission_check_test.rb
  rm test/browser/preferences_token_access_test.rb
  rm test/browser/reporting_test.rb
  rm test/browser/setting_test.rb
  # test/browser/signup_password_change_and_reset_test.rb
  # test/browser/swich_to_user_test.rb
  # test/browser/taskbar_session_test.rb
  # test/browser/taskbar_task_test.rb
  # test/browser/translation_test.rb
  rm test/browser/user_access_permissions_test.rb
  rm test/browser/user_switch_cache_test.rb

elif [ "$LEVEL" == '2' ]; then
  echo "slicing level 2"

  # only ticket action 2/3
  # test/browser/aaa_getting_started_test.rb
  # test/browser/abb_one_group_test.rb
  rm test/browser/admin_channel_email_test.rb
  rm test/browser/admin_calendar_sla_test.rb
  rm test/browser/admin_drag_drop_to_new_group_test.rb
  rm test/browser/admin_object_manager_test.rb
  rm test/browser/admin_object_manager_tree_select_test.rb
  rm test/browser/admin_overview_test.rb
  rm test/browser/admin_permissions_granular_vs_full_test.rb
  #rm test/browser/admin_role_test.rb
  rm test/browser/agent_navigation_and_title_test.rb
  rm test/browser/agent_organization_profile_test.rb
  rm test/browser/agent_ticket_attachment_test.rb
  rm test/browser/agent_ticket_create_available_types_test.rb
  rm test/browser/agent_ticket_create_attachment_missing_after_reload_test.rb
  rm test/browser/agent_ticket_create_cc_tokenizer_test.rb
  rm test/browser/agent_ticket_create_default_type_test.rb
  rm test/browser/agent_ticket_create_reset_customer_selection_test.rb
  rm test/browser/agent_ticket_create_template_test.rb
  rm test/browser/agent_ticket_email_reply_keep_body_test.rb
  rm test/browser/agent_ticket_email_signature_test.rb
  rm test/browser/agent_ticket_link_test.rb
  rm test/browser/agent_ticket_macro_test.rb
  # test/browser/agent_ticket_merge_test.rb
  rm test/browser/agent_ticket_online_notification_test.rb
  rm test/browser/agent_ticket_overview_group_by_organization_test.rb
  rm test/browser/agent_ticket_overview_level0_test.rb
  rm test/browser/agent_ticket_overview_level1_test.rb
  rm test/browser/agent_ticket_overview_pending_til_test.rb
  rm test/browser/agent_ticket_overview_tab_test.rb
  rm test/browser/agent_ticket_tag_test.rb
  rm test/browser/agent_ticket_task_changed_test.rb
  # test/browser/agent_ticket_text_module_test.rb
  # test/browser/agent_ticket_time_accounting_test.rb
  # test/browser/agent_ticket_update1_test.rb
  # test/browser/agent_ticket_update2_test.rb
  # test/browser/agent_ticket_update3_test.rb
  # test/browser/agent_ticket_update4_test.rb
  # rm test/browser/agent_ticket_update5_test.rb
  # rm test/browser/agent_ticket_update_with_attachment_refresh_test.rb
  # test/browser/agent_ticket_update_and_reload_test.rb
  # test/browser/agent_ticket_zoom_hide_test.rb
  rm test/browser/agent_user_manage_test.rb
  rm test/browser/agent_user_profile_test.rb
  rm test/browser/auth_test.rb
  rm test/browser/chat_test.rb
  rm test/browser/chat_no_jquery_test.rb
  rm test/browser/customer_ticket_create_fields_test.rb
  rm test/browser/customer_ticket_create_test.rb
  rm test/browser/first_steps_test.rb
  rm test/browser/form_test.rb
  rm test/browser/integration_test.rb
  rm test/browser/keyboard_shortcuts_test.rb
  rm test/browser/maintenance_app_version_test.rb
  rm test/browser/maintenance_mode_test.rb
  rm test/browser/maintenance_session_message_test.rb
  rm test/browser/manage_test.rb
  rm test/browser/monitoring_test.rb
  rm test/browser/integration_sipgate_test.rb
  rm test/browser/integration_cti_test.rb
  rm test/browser/preferences_language_test.rb
  rm test/browser/preferences_permission_check_test.rb
  rm test/browser/preferences_token_access_test.rb
  rm test/browser/reporting_test.rb
  rm test/browser/setting_test.rb
  rm test/browser/signup_password_change_and_reset_test.rb
  rm test/browser/switch_to_user_test.rb
  rm test/browser/taskbar_session_test.rb
  rm test/browser/taskbar_task_test.rb
  rm test/browser/translation_test.rb
  # test/browser/user_access_permissions_test.rb
  # test/browser/user_switch_cache_test.rb

elif [ "$LEVEL" == '3' ]; then
  echo "slicing level 3"

  # only ticket action 2/3
  # test/browser/aaa_getting_started_test.rb
  # test/browser/abb_one_group_test.rb
  rm test/browser/admin_channel_email_test.rb
  rm test/browser/admin_calendar_sla_test.rb
  rm test/browser/admin_drag_drop_to_new_group_test.rb
  rm test/browser/admin_object_manager_test.rb
  rm test/browser/admin_object_manager_tree_select_test.rb
  rm test/browser/admin_overview_test.rb
  rm test/browser/admin_permissions_granular_vs_full_test.rb
  rm test/browser/admin_role_test.rb
  rm test/browser/agent_navigation_and_title_test.rb
  rm test/browser/agent_organization_profile_test.rb
  # test/browser/agent_ticket_attachment_test.rb
  # rm test/browser/agent_ticket_create_available_types_test.rb
  # rm test/browser/agent_ticket_create_attachment_missing_after_reload_test.rb
  #rm test/browser/agent_ticket_create_cc_tokenizer_test.rb
  # rm test/browser/agent_ticket_create_default_type_test.rb
  # test/browser/agent_ticket_create_reset_customer_selection_test.rb
  # test/browser/agent_ticket_create_template_test.rb
  # test/browser/agent_ticket_email_reply_keep_body_test.rb
  # test/browser/agent_ticket_email_signature_test.rb
  # test/browser/agent_ticket_link_test.rb
  # test/browser/agent_ticket_macro_test.rb
  rm test/browser/agent_ticket_merge_test.rb
  rm test/browser/agent_ticket_online_notification_test.rb
  rm test/browser/agent_ticket_overview_group_by_organization_test.rb
  rm test/browser/agent_ticket_overview_level0_test.rb
  rm test/browser/agent_ticket_overview_level1_test.rb
  rm test/browser/agent_ticket_overview_pending_til_test.rb
  rm test/browser/agent_ticket_overview_tab_test.rb
  # test/browser/agent_ticket_tag_test.rb
  # test/browser/agent_ticket_task_changed_test.rb
  rm test/browser/agent_ticket_text_module_test.rb
  rm test/browser/agent_ticket_time_accounting_test.rb
  rm test/browser/agent_ticket_update1_test.rb
  rm test/browser/agent_ticket_update2_test.rb
  rm test/browser/agent_ticket_update3_test.rb
  rm test/browser/agent_ticket_update4_test.rb
  rm test/browser/agent_ticket_update5_test.rb
  rm test/browser/agent_ticket_update_with_attachment_refresh_test.rb
  rm test/browser/agent_ticket_update_and_reload_test.rb
  rm test/browser/agent_ticket_zoom_hide_test.rb
  rm test/browser/agent_user_manage_test.rb
  rm test/browser/agent_user_profile_test.rb
  rm test/browser/auth_test.rb
  rm test/browser/chat_test.rb
  rm test/browser/chat_no_jquery_test.rb
  rm test/browser/customer_ticket_create_fields_test.rb
  rm test/browser/customer_ticket_create_test.rb
  rm test/browser/first_steps_test.rb
  rm test/browser/form_test.rb
  rm test/browser/integration_test.rb
  rm test/browser/keyboard_shortcuts_test.rb
  rm test/browser/maintenance_app_version_test.rb
  rm test/browser/maintenance_mode_test.rb
  rm test/browser/maintenance_session_message_test.rb
  rm test/browser/manage_test.rb
  rm test/browser/monitoring_test.rb
  rm test/browser/integration_sipgate_test.rb
  rm test/browser/integration_cti_test.rb
  rm test/browser/preferences_language_test.rb
  rm test/browser/preferences_permission_check_test.rb
  rm test/browser/preferences_token_access_test.rb
  rm test/browser/reporting_test.rb
  rm test/browser/setting_test.rb
  rm test/browser/signup_password_change_and_reset_test.rb
  rm test/browser/switch_to_user_test.rb
  rm test/browser/taskbar_session_test.rb
  rm test/browser/taskbar_task_test.rb
  rm test/browser/translation_test.rb
  rm test/browser/user_access_permissions_test.rb
  rm test/browser/user_switch_cache_test.rb

elif [ "$LEVEL" == '4' ]; then
  echo "slicing level 4"

  # only ticket action 3/3
  # test/browser/aaa_getting_started_test.rb
  # test/browser/abb_one_group_test.rb
  rm test/browser/admin_channel_email_test.rb
  rm test/browser/admin_calendar_sla_test.rb
  rm test/browser/admin_drag_drop_to_new_group_test.rb
  rm test/browser/admin_object_manager_test.rb
  rm test/browser/admin_object_manager_tree_select_test.rb
  rm test/browser/admin_overview_test.rb
  rm test/browser/admin_permissions_granular_vs_full_test.rb
  rm test/browser/admin_role_test.rb
  rm test/browser/agent_navigation_and_title_test.rb
  rm test/browser/agent_organization_profile_test.rb
  rm test/browser/agent_ticket_attachment_test.rb
  rm test/browser/agent_ticket_create_available_types_test.rb
  rm test/browser/agent_ticket_create_attachment_missing_after_reload_test.rb
  rm test/browser/agent_ticket_create_cc_tokenizer_test.rb
  rm test/browser/agent_ticket_create_default_type_test.rb
  rm test/browser/agent_ticket_create_reset_customer_selection_test.rb
  rm test/browser/agent_ticket_create_template_test.rb
  rm test/browser/agent_ticket_email_reply_keep_body_test.rb
  rm test/browser/agent_ticket_email_signature_test.rb
  rm test/browser/agent_ticket_link_test.rb
  rm test/browser/agent_ticket_macro_test.rb
  rm test/browser/agent_ticket_merge_test.rb
  # test/browser/agent_ticket_online_notification_test.rb
  # test/browser/agent_ticket_overview_group_by_organization_test.rb
  # test/browser/agent_ticket_overview_level0_test.rb
  # test/browser/agent_ticket_overview_level1_test.rb
  # test/browser/agent_ticket_overview_pending_til_test.rb
  # test/browser/agent_ticket_overview_tab_test.rb
  rm test/browser/agent_ticket_tag_test.rb
  rm test/browser/agent_ticket_task_changed_test.rb
  rm test/browser/agent_ticket_text_module_test.rb
  rm test/browser/agent_ticket_time_accounting_test.rb
  rm test/browser/agent_ticket_update1_test.rb
  rm test/browser/agent_ticket_update2_test.rb
  rm test/browser/agent_ticket_update3_test.rb
  rm test/browser/agent_ticket_update4_test.rb
  rm test/browser/agent_ticket_update5_test.rb
  rm test/browser/agent_ticket_update_with_attachment_refresh_test.rb
  rm test/browser/agent_ticket_update_and_reload_test.rb
  rm test/browser/agent_ticket_zoom_hide_test.rb
  rm test/browser/agent_user_manage_test.rb
  rm test/browser/agent_user_profile_test.rb
  rm test/browser/auth_test.rb
  rm test/browser/chat_test.rb
  rm test/browser/chat_no_jquery_test.rb
  # test/browser/customer_ticket_create_fields_test.rb
  # test/browser/customer_ticket_create_test.rb
  rm test/browser/first_steps_test.rb
  rm test/browser/form_test.rb
  rm test/browser/integration_test.rb
  rm test/browser/keyboard_shortcuts_test.rb
  rm test/browser/maintenance_app_version_test.rb
  rm test/browser/maintenance_mode_test.rb
  rm test/browser/maintenance_session_message_test.rb
  rm test/browser/manage_test.rb
  rm test/browser/monitoring_test.rb
  rm test/browser/integration_sipgate_test.rb
  rm test/browser/integration_cti_test.rb
  rm test/browser/preferences_language_test.rb
  rm test/browser/preferences_permission_check_test.rb
  rm test/browser/preferences_token_access_test.rb
  rm test/browser/reporting_test.rb
  rm test/browser/setting_test.rb
  rm test/browser/signup_password_change_and_reset_test.rb
  rm test/browser/switch_to_user_test.rb
  rm test/browser/taskbar_session_test.rb
  rm test/browser/taskbar_task_test.rb
  rm test/browser/translation_test.rb
  rm test/browser/user_access_permissions_test.rb
  rm test/browser/user_switch_cache_test.rb

elif [ "$LEVEL" == '5' ]; then
  echo "slicing level 5"

  # only profile action & admin
  # test/browser/abb_one_group_test.rb
  # test/browser/admin_channel_email_test.rb
  # test/browser/admin_calendar_sla_test.rb
  # rm test/browser/admin_drag_drop_to_new_group_test.rb
  # test/browser/admin_object_manager_test.rb
  # test/browser/admin_object_manager_tree_select_test.rb
  # test/browser/admin_overview_test.rb
  # rm test/browser/admin_permissions_granular_vs_full_test.rb
  rm test/browser/admin_role_test.rb
  rm test/browser/agent_navigation_and_title_test.rb
  rm test/browser/agent_organization_profile_test.rb
  rm test/browser/agent_ticket_attachment_test.rb
  rm test/browser/agent_ticket_create_available_types_test.rb
  rm test/browser/agent_ticket_create_attachment_missing_after_reload_test.rb
  rm test/browser/agent_ticket_create_cc_tokenizer_test.rb
  rm test/browser/agent_ticket_create_default_type_test.rb
  rm test/browser/agent_ticket_create_reset_customer_selection_test.rb
  rm test/browser/agent_ticket_create_template_test.rb
  rm test/browser/agent_ticket_email_reply_keep_body_test.rb
  rm test/browser/agent_ticket_email_signature_test.rb
  rm test/browser/agent_ticket_link_test.rb
  rm test/browser/agent_ticket_macro_test.rb
  rm test/browser/agent_ticket_merge_test.rb
  rm test/browser/agent_ticket_online_notification_test.rb
  rm test/browser/agent_ticket_overview_group_by_organization_test.rb
  rm test/browser/agent_ticket_overview_level0_test.rb
  rm test/browser/agent_ticket_overview_level1_test.rb
  rm test/browser/agent_ticket_overview_pending_til_test.rb
  rm test/browser/agent_ticket_overview_tab_test.rb
  rm test/browser/agent_ticket_tag_test.rb
  rm test/browser/agent_ticket_task_changed_test.rb
  rm test/browser/agent_ticket_text_module_test.rb
  rm test/browser/agent_ticket_time_accounting_test.rb
  rm test/browser/agent_ticket_update1_test.rb
  rm test/browser/agent_ticket_update2_test.rb
  rm test/browser/agent_ticket_update3_test.rb
  rm test/browser/agent_ticket_update4_test.rb
  rm test/browser/agent_ticket_update5_test.rb
  rm test/browser/agent_ticket_update_with_attachment_refresh_test.rb
  rm test/browser/agent_ticket_update_and_reload_test.rb
  rm test/browser/agent_ticket_zoom_hide_test.rb
  # test/browser/agent_user_manage_test.rb
  # test/browser/agent_user_profile_test.rb
  rm test/browser/auth_test.rb
  rm test/browser/chat_test.rb
  rm test/browser/chat_no_jquery_test.rb
  rm test/browser/customer_ticket_create_fields_test.rb
  rm test/browser/customer_ticket_create_test.rb
  rm test/browser/first_steps_test.rb
  rm test/browser/form_test.rb
  rm test/browser/integration_test.rb
  rm test/browser/keyboard_shortcuts_test.rb
  rm test/browser/maintenance_app_version_test.rb
  rm test/browser/maintenance_mode_test.rb
  rm test/browser/maintenance_session_message_test.rb
  rm test/browser/manage_test.rb
  rm test/browser/monitoring_test.rb
  rm test/browser/integration_sipgate_test.rb
  rm test/browser/integration_cti_test.rb
  rm test/browser/preferences_language_test.rb
  rm test/browser/preferences_permission_check_test.rb
  rm test/browser/preferences_token_access_test.rb
  rm test/browser/reporting_test.rb
  rm test/browser/setting_test.rb
  rm test/browser/signup_password_change_and_reset_test.rb
  rm test/browser/switch_to_user_test.rb
  rm test/browser/taskbar_session_test.rb
  rm test/browser/taskbar_task_test.rb
  rm test/browser/translation_test.rb
  rm test/browser/user_access_permissions_test.rb
  rm test/browser/user_switch_cache_test.rb

elif [ "$LEVEL" == '6' ]; then
  echo "slicing level 6"

  # only profile action & admin
  rm test/browser/aaa_getting_started_test.rb
  cp contrib/auto_wizard_test.json auto_wizard.json
  cp test/integration/aaa_auto_wizard_base_setup_test.rb test/browser/aaa_auto_wizard_base_setup_test.rb
  rm test/browser/abb_one_group_test.rb
  rm test/browser/admin_channel_email_test.rb
  rm test/browser/admin_calendar_sla_test.rb
  rm test/browser/admin_drag_drop_to_new_group_test.rb
  rm test/browser/admin_object_manager_test.rb
  rm test/browser/admin_object_manager_tree_select_test.rb
  rm test/browser/admin_overview_test.rb
  rm test/browser/admin_permissions_granular_vs_full_test.rb
  rm test/browser/admin_role_test.rb
  rm test/browser/agent_navigation_and_title_test.rb
  rm test/browser/agent_organization_profile_test.rb
  rm test/browser/agent_ticket_attachment_test.rb
  rm test/browser/agent_ticket_create_available_types_test.rb
  rm test/browser/agent_ticket_create_attachment_missing_after_reload_test.rb
  rm test/browser/agent_ticket_create_cc_tokenizer_test.rb
  rm test/browser/agent_ticket_create_default_type_test.rb
  rm test/browser/agent_ticket_create_reset_customer_selection_test.rb
  rm test/browser/agent_ticket_create_template_test.rb
  rm test/browser/agent_ticket_email_reply_keep_body_test.rb
  rm test/browser/agent_ticket_email_signature_test.rb
  rm test/browser/agent_ticket_link_test.rb
  rm test/browser/agent_ticket_macro_test.rb
  rm test/browser/agent_ticket_merge_test.rb
  rm test/browser/agent_ticket_online_notification_test.rb
  rm test/browser/agent_ticket_overview_group_by_organization_test.rb
  rm test/browser/agent_ticket_overview_level0_test.rb
  rm test/browser/agent_ticket_overview_level1_test.rb
  rm test/browser/agent_ticket_overview_pending_til_test.rb
  rm test/browser/agent_ticket_overview_tab_test.rb
  rm test/browser/agent_ticket_tag_test.rb
  rm test/browser/agent_ticket_task_changed_test.rb
  rm test/browser/agent_ticket_text_module_test.rb
  rm test/browser/agent_ticket_time_accounting_test.rb
  rm test/browser/agent_ticket_update1_test.rb
  rm test/browser/agent_ticket_update2_test.rb
  rm test/browser/agent_ticket_update3_test.rb
  rm test/browser/agent_ticket_update4_test.rb
  rm test/browser/agent_ticket_update5_test.rb
  rm test/browser/agent_ticket_update_with_attachment_refresh_test.rb
  rm test/browser/agent_ticket_update_and_reload_test.rb
  rm test/browser/agent_ticket_zoom_hide_test.rb
  rm test/browser/agent_user_manage_test.rb
  rm test/browser/agent_user_profile_test.rb
  rm test/browser/auth_test.rb
  # test/browser/chat_test.rb
  # test/browser/chat_no_jquery_test.rb
  rm test/browser/customer_ticket_create_fields_test.rb
  rm test/browser/customer_ticket_create_test.rb
  # test/browser/first_steps_test.rb
  rm test/browser/form_test.rb
  # test/browser/integration_test.rb
  # test/browser/keyboard_shortcuts_test.rb
  rm test/browser/maintenance_app_version_test.rb
  rm test/browser/maintenance_mode_test.rb
  rm test/browser/maintenance_session_message_test.rb
  rm test/browser/manage_test.rb
  rm test/browser/monitoring_test.rb
  # rm test/browser/integration_sipgate_test.rb
  # rm test/browser/integration_cti_test.rb
  # test/browser/preferences_language_test.rb
  # test/browser/preferences_permission_check_test.rb
  # test/browser/preferences_token_access_test.rb
  # test/browser/reporting_test.rb
  # test/browser/setting_test.rb
  rm test/browser/signup_password_change_and_reset_test.rb
  rm test/browser/switch_to_user_test.rb
  rm test/browser/taskbar_session_test.rb
  rm test/browser/taskbar_task_test.rb
  rm test/browser/translation_test.rb
  rm test/browser/user_access_permissions_test.rb
  rm test/browser/user_switch_cache_test.rb

else
  echo "ERROR: Invalid level $LEVEL - 1, 2, 3, 4, 5 or 6 is available"
  exit 1
fi
