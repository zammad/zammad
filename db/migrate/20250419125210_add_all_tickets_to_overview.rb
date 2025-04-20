# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class AddAllTicketsToOverview < ActiveRecord::Migration[7.2]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    overview_role = Role.find_by(name: 'Agent')
    # Create new overview for all tickets created today. Adding to the top of the lits
    Overview.create_or_update(
      name:          'All Tickets Created Today',
      link:          'all_created_today',
      prio:          1,
      role_ids:      [overview_role.id],
      condition:     {
        'ticket.created_at'                     => {
          operator: 'after (absolute)',
          value:    Time.zone.today.midnight.iso8601,
        },
      },
      order:         {
        by:        'created_at',
        direction: 'ASC',
      },
      view:          {
        d:                 %w[title customer group owner created_at],
        s:                 %w[title customer group owner created_at],
        m:                 %w[number title customer group owner created_at],
        view_mode_default: 's',
      },
      updated_by_id: 1,
      created_by_id: 1,
    )
  end
end
