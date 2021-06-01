# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class FollowUpMerged < ActiveRecord::Migration[4.2]
  def up

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.create_if_not_exists(
      title:       'Defines postmaster filter.',
      name:        '0110_postmaster_filter_follow_up_merged',
      area:        'Postmaster::PreFilter',
      description: 'Defines postmaster filter to identify follow-up ticket for merged tickets.',
      options:     {},
      state:       'Channel::Filter::FollowUpMerged',
      frontend:    false
    )
  end
end
