# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class TicketOverviewQueryPollingSetting < ActiveRecord::Migration[6.1]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.create_if_not_exists(
      title:       'Ticket Overview Query Polling',
      name:        'ui_ticket_overview_query_polling',
      area:        'UI::TicketOverview::QueryPolling',
      description: 'System-wide configuration of the query polling mechanism for ticket overviews.',
      options:     {},
      state:       {
        enabled:    true,
        page_size:  30,
        background: {
          calculation_count: 3,
          interval_sec:      10,
          cache_ttl_sec:     10,
        },
        foreground: {
          interval_sec:  5,
          cache_ttl_sec: 5,
        },
        counts:     {
          interval_sec:  60,
          cache_ttl_sec: 60,
        },
      },
      preferences: {
        permission: ['admin.ui'],
      },
      frontend:    true
    )
  end
end
