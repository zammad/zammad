# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class OverviewUpdates < ActiveRecord::Migration[6.0]
  def change
    return if !Setting.exists?(name: 'system_init_done')

    # Only update overviews that still have the original/default name and link.
    overviews_update = [
      {
        name:     'My Assigned Tickets',
        link:     'my_assigned',
        old_name: 'My assigned Tickets',
      },
      {
        name:     'Unassigned & Open Tickets',
        link:     'all_unassigned',
        old_name: 'Unassigned & Open',
      },
      {
        name:     'My Pending Reached Tickets',
        link:     'my_pending_reached',
        old_name: 'My pending reached Tickets',
      },
      {
        name:     'My Subscribed Tickets',
        link:     'my_subscribed_tickets',
        old_name: 'My subscribed Tickets',
      },
      {
        name:     'Open Tickets',
        link:     'all_open',
        old_name: 'Open',
      },
      {
        name:     'Pending Reached Tickets',
        link:     'all_pending_reached',
        old_name: 'Pending reached',
      },
      {
        name:     'Escalated Tickets',
        link:     'all_escalated',
        old_name: 'Escalated',
      },
      {
        name:     'My Replacement Tickets',
        link:     'my_replacement_tickets',
        old_name: 'My replacement Tickets',
      },
    ]

    overviews_update.each do |overview|
      fetched_overview = Overview.find_by(link: overview[:link], name: overview[:old_name])
      next if !fetched_overview

      if overview[:name]
        # p "Updating name of #{overview[:link]} to #{overview[:name]}"
        fetched_overview.name = overview[:name]
      end

      fetched_overview.save!
    end
  end
end
