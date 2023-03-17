# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class CreateTicketReopenTime < ActiveRecord::Migration[5.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    change_table :tickets do |t|
      t.timestamp :last_close_at, limit: 3, null: true
    end

    Ticket.reset_column_information

    change_table :groups do |t|
      t.integer :reopen_time_in_days, null: true
    end

    Group.reset_column_information

    UserInfo.current_user_id = 1

    ObjectManager::Attribute.add(
      force:       true,
      object:      'Group',
      name:        'follow_up_possible',
      display:     'Follow-up possible',
      data_type:   'select',
      data_option: {
        default:   'yes',
        options:   {
          yes:                           'yes',
          new_ticket:                    'do not reopen ticket but create new ticket',
          new_ticket_after_certain_time: 'do not reopen ticket after certain time but create new ticket',
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
            null: false,
          },
        },
        edit:   {
          '-all-' => {
            null: false,
          },
        },
      },
      to_create:   false,
      to_migrate:  false,
      to_delete:   false,
      position:    400,
    )

    ObjectManager::Attribute.add(
      force:         true,
      object:        'Group',
      name:          'reopen_time_in_days',
      display:       'Reopening time in days',
      data_type:     'integer',
      data_option:   {
        default:   '',
        min:       1,
        max:       3650,
        null:      true,
        note:      'Allow reopening of tickets within a certain time.',
        translate: true
      },
      editable:      false,
      active:        true,
      screens:       {
        create: { 'admin.group': { shown: false, required: false } },
        edit:   { 'admin.group': { shown: false, required: false } },
        view:   { 'admin.group': { shown: false } }
      },
      to_create:     false,
      to_migrate:    false,
      to_delete:     false,
      position:      410,
      created_by_id: 1,
      updated_by_id: 1,
    )

    CoreWorkflow.create_if_not_exists(
      name:               'base - show reopen_time_in_days',
      object:             'Group',
      condition_saved:    {},
      condition_selected: { 'group.follow_up_possible'=>{ 'operator' => 'is', 'value' => ['new_ticket_after_certain_time'] } },
      perform:            { 'group.reopen_time_in_days'=>{ 'operator' => %w[show set_mandatory], 'show' => 'true', 'set_mandatory' => 'true' } },
      preferences:        { 'screen'=>%w[create edit] },
      changeable:         false,
      active:             true,
      created_by_id:      1,
      updated_by_id:      1,
    )
  end
end
