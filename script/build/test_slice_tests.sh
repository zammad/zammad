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
  rm test/browser/admin_drag_drop_to_new_group_test.rb
  rm test/browser/admin_overview_test.rb
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
  rm test/browser/agent_ticket_update_with_attachment_refresh_test.rb
  rm test/browser/agent_ticket_update_and_reload_test.rb
  rm test/browser/agent_ticket_zoom_hide_test.rb
  rm test/browser/agent_user_manage_test.rb
  rm test/browser/agent_user_profile_test.rb
  rm test/browser/customer_ticket_create_test.rb
  # test/browser/manage_test.rb
  # test/browser/swich_to_user_test.rb
  # test/browser/taskbar_session_test.rb
  # test/browser/taskbar_task_test.rb
  rm test/browser/user_access_permissions_test.rb
  rm test/browser/user_switch_cache_test.rb

elif [ "$LEVEL" == '2' ]; then
  echo "slicing level 2"

  # only ticket action 2/3
  # test/browser/aaa_getting_started_test.rb
  # test/browser/abb_one_group_test.rb
  rm test/browser/admin_drag_drop_to_new_group_test.rb
  rm test/browser/admin_overview_test.rb
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
  # rm test/browser/agent_ticket_update_with_attachment_refresh_test.rb
  # test/browser/agent_ticket_update_and_reload_test.rb
  # test/browser/agent_ticket_zoom_hide_test.rb
  rm test/browser/agent_user_manage_test.rb
  rm test/browser/agent_user_profile_test.rb
  rm test/browser/customer_ticket_create_test.rb
  rm test/browser/manage_test.rb
  rm test/browser/taskbar_session_test.rb
  rm test/browser/taskbar_task_test.rb
  # test/browser/user_access_permissions_test.rb
  # test/browser/user_switch_cache_test.rb

elif [ "$LEVEL" == '3' ]; then
  echo "slicing level 3"

  # only ticket action 2/3
  # test/browser/aaa_getting_started_test.rb
  # test/browser/abb_one_group_test.rb
  rm test/browser/admin_drag_drop_to_new_group_test.rb
  rm test/browser/admin_overview_test.rb
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
  rm test/browser/agent_ticket_update_with_attachment_refresh_test.rb
  rm test/browser/agent_ticket_update_and_reload_test.rb
  rm test/browser/agent_ticket_zoom_hide_test.rb
  rm test/browser/agent_user_manage_test.rb
  rm test/browser/agent_user_profile_test.rb
  rm test/browser/customer_ticket_create_test.rb
  rm test/browser/manage_test.rb
  rm test/browser/taskbar_session_test.rb
  rm test/browser/taskbar_task_test.rb
  rm test/browser/user_access_permissions_test.rb
  rm test/browser/user_switch_cache_test.rb

elif [ "$LEVEL" == '4' ]; then
  echo "slicing level 4"

  # only ticket action 3/3
  # test/browser/aaa_getting_started_test.rb
  # test/browser/abb_one_group_test.rb
  rm test/browser/admin_drag_drop_to_new_group_test.rb
  rm test/browser/admin_overview_test.rb
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
  rm test/browser/agent_ticket_update_with_attachment_refresh_test.rb
  rm test/browser/agent_ticket_update_and_reload_test.rb
  rm test/browser/agent_ticket_zoom_hide_test.rb
  rm test/browser/agent_user_manage_test.rb
  rm test/browser/agent_user_profile_test.rb
  # test/browser/customer_ticket_create_test.rb
  rm test/browser/manage_test.rb
  rm test/browser/taskbar_session_test.rb
  rm test/browser/taskbar_task_test.rb
  rm test/browser/user_access_permissions_test.rb
  rm test/browser/user_switch_cache_test.rb

elif [ "$LEVEL" == '5' ]; then
  echo "slicing level 5"

  # only profile action & admin
  # test/browser/abb_one_group_test.rb
  # rm test/browser/admin_drag_drop_to_new_group_test.rb
  # test/browser/admin_overview_test.rb
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
  rm test/browser/agent_ticket_update_with_attachment_refresh_test.rb
  rm test/browser/agent_ticket_update_and_reload_test.rb
  rm test/browser/agent_ticket_zoom_hide_test.rb
  # test/browser/agent_user_manage_test.rb
  # test/browser/agent_user_profile_test.rb
  rm test/browser/customer_ticket_create_test.rb
  rm test/browser/manage_test.rb
  rm test/browser/taskbar_session_test.rb
  rm test/browser/taskbar_task_test.rb
  rm test/browser/user_access_permissions_test.rb
  rm test/browser/user_switch_cache_test.rb

else
  echo "ERROR: Invalid level $LEVEL - 1, 2, 3, 4 or 5 is available"
  exit 1
fi
