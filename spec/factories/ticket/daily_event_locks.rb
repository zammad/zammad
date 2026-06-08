# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

FactoryBot.define do
  factory :'ticket/daily_event_lock', aliases: %i[ticket_daily_event_lock] do
    date           { Time.current.to_date }
    lock_type      { 'notification' }
    lock_activator { 'reminder_reached' }
    ticket         { association :ticket }
  end
end
