# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Issue2455FollowUpAssignment < ActiveRecord::Migration[6.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Group.where(follow_up_assignment: false).find_each do |group|
      group.update(follow_up_assignment: true)
    end

    Setting.create_if_not_exists(
      title:       'Defines postmaster filter.',
      name:        '0009_postmaster_filter_follow_up_assignment',
      area:        'Postmaster::PreFilter',
      description: 'Defines postmaster filter to set the owner (based on group follow up assignment).',
      options:     {},
      state:       'Channel::Filter::FollowUpAssignment',
      frontend:    false
    )
  end
end
