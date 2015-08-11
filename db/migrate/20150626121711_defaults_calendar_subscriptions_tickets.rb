class DefaultsCalendarSubscriptionsTickets < ActiveRecord::Migration
  def up
    Setting.create_if_not_exists(
      title: 'Default calendar Tickets subscriptions',
      name: 'defaults_calendar_subscriptions_tickets',
      area: 'Defaults::CalendarSubscriptions',
      description: 'Defines the default calendar Tickets subscription settings.',
      options: {},
      state: {
        escalation: {
          own: true,
          not_assigned: false,
        },
        new_open: {
          own: true,
          not_assigned: false,
        },
        pending: {
          own: true,
          not_assigned: false,
        }
      },
      frontend: true
    )
  end

  def down
  end
end
