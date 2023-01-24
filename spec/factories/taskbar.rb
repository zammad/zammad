# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

FactoryBot.define do
  factory :taskbar do
    key                      { 'Ticket-1234' }
    add_attribute(:callback) { 'TicketZoom' }
    params                   { {} }
    state                    { nil }
    prio                     { 1 }
    notify                   { false }
    user_id                  { 1 }
  end
end
