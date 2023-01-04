# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class JiraConfig < ActiveRecord::Migration[4.2]
  def up

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.create_if_not_exists(
      title:       'Defines postmaster filter.',
      name:        '5400_postmaster_filter_jira_check',
      area:        'Postmaster::PreFilter',
      description: 'Defines postmaster filter to identify jira mails for correct follow-ups.',
      options:     {},
      state:       'Channel::Filter::JiraCheck',
      frontend:    false
    )

    Setting.create_if_not_exists(
      title:       'Defines postmaster filter.',
      name:        '5401_postmaster_filter_jira_check',
      area:        'Postmaster::PostFilter',
      description: 'Defines postmaster filter to identify jira mails for correct follow-ups.',
      options:     {},
      state:       'Channel::Filter::JiraCheck',
      frontend:    false
    )
  end

end
