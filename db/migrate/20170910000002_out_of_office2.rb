# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class OutOfOffice2 < ActiveRecord::Migration[4.2]
  def up

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    if !ActiveRecord::Base.connection.column_exists?(:overviews, :out_of_office)
      add_column :overviews, :out_of_office, :boolean, null: false, default: false
      Overview.reset_column_information
    end

    if !ActiveRecord::Base.connection.column_exists?(:users, :out_of_office)
      add_column :users, :out_of_office, :boolean, null: false, default: false
      add_column :users, :out_of_office_start_at, :date, null: true
      add_column :users, :out_of_office_end_at, :date, null: true
      add_column :users, :out_of_office_replacement_id, :integer, null: true

      add_index :users, %i[out_of_office out_of_office_start_at out_of_office_end_at], name: 'index_out_of_office'
      add_index :users, [:out_of_office_replacement_id]
      add_foreign_key :users, :users, column: :out_of_office_replacement_id
      User.reset_column_information
    end

    role_ids = Role.with_permissions(['ticket.agent']).map(&:id)
    Overview.create_or_update(
      name:          'My replacement Tickets',
      link:          'my_replacement_tickets',
      prio:          1080,
      role_ids:      role_ids,
      out_of_office: true,
      condition:     {
        'ticket.state_id'                     => {
          operator: 'is',
          value:    Ticket::State.by_category(:open).pluck(:id),
        },
        'ticket.out_of_office_replacement_id' => {
          operator:      'is',
          pre_condition: 'current_user.id',
        },
      },
      order:         {
        by:        'created_at',
        direction: 'DESC',
      },
      view:          {
        d:                 %w[title customer group owner escalation_at],
        s:                 %w[title customer group owner escalation_at],
        m:                 %w[number title customer group owner escalation_at],
        view_mode_default: 's',
      },
      updated_by_id: 1,
      created_by_id: 1,
    )

    Cache.clear
  end
end
