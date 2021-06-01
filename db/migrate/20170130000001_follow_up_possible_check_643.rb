# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class FollowUpPossibleCheck643 < ActiveRecord::Migration[4.2]
  def up

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.create_if_not_exists(
      title:       'Define postmaster filter.',
      name:        '0200_postmaster_filter_follow_up_possible_check',
      area:        'Postmaster::PreFilter',
      description: 'Define postmaster filter to check if follow-ups get created (based on admin settings).',
      options:     {},
      state:       'Channel::Filter::FollowUpPossibleCheck',
      frontend:    false
    )

    ObjectManager::Attribute.add(
      force:       true,
      object:      'Group',
      name:        'follow_up_possible',
      display:     'Follow-up possible',
      data_type:   'select',
      data_option: {
        default:   'yes',
        options:   {
          yes:        'yes',
          new_ticket: 'do not reopen Ticket but create new Ticket'
        },
        null:      false,
        note:      'Follow-up for closed ticket possible or not.',
        translate: true
      },
      editable:    false,
      active:      true,
      screens:     {
        create: {
          '-all-' => {
            null: true,
          },
        },
        edit:   {
          '-all-' => {
            null: true,
          },
        },
      },
      to_create:   false,
      to_migrate:  false,
      to_delete:   false,
      position:    400,
    )

  end
end
