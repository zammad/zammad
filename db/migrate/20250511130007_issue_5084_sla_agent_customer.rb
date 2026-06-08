# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Issue5084SlaAgentCustomer < ActiveRecord::Migration[7.2]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting
      .find_by!(name: '0015_postmaster_filter_identify_sender')
      .update!(name: '6500_postmaster_filter_identify_sender')

    Setting.create!(
      name:        '0015_postmaster_filter_identify_session_user',
      title:       'Defines postmaster filter.',
      area:        'Postmaster::PreFilter',
      description: 'Defines postmaster filter to identify session user.',
      options:     {},
      state:       'Channel::Filter::IdentifySessionUser',
      frontend:    false
    )

    Setting.create!(
      name:        '6005_postmaster_filter_identify_group',
      title:       'Defines postmaster filter.',
      area:        'Postmaster::PreFilter',
      description: 'Defines postmaster filter to identify ticket group.',
      options:     {},
      state:       'Channel::Filter::IdentifyGroup',
      frontend:    false
    )

    Setting
      .find_by!(name: '0012_postmaster_filter_sender_is_system_address')
      .update!(name: '6105_postmaster_filter_sender_is_system_address')
  end
end
