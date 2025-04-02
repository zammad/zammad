# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class AddChannelMicrosoftGraph < ActiveRecord::Migration[7.2]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Permission.create_if_not_exists(
      name:        'admin.channel_microsoft_graph',
      label:       'Microsoft Graph',
      description: 'Manage Microsoft Graph mail channel of your system.',
      preferences: { prio: 1255 }
    )

    settings = %w[
      ticket_subject_size
      ticket_subject_re
      ticket_subject_fwd
      ticket_define_email_from
      ticket_define_email_from_separator
      postmaster_max_size
      postmaster_follow_up_search_in
      postmaster_sender_based_on_reply_to
      postmaster_sender_is_agent_search_for_customer
      postmaster_send_reject_if_mail_too_large
      notification_sender
      send_no_auto_response_reg_exp
    ]

    Setting.where(name: settings).each do |setting|
      setting.preferences[:permission] += ['admin.channel_microsoft_graph']
      setting.save
    end
  end
end
