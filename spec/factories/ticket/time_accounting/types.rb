# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

FactoryBot.define do
  factory :ticket_time_accounting_type, class: 'Ticket::TimeAccounting::Type' do
    name { Faker::Name.unique.name }

    created_by_id { 1 }
    updated_by_id { 1 }
  end
end
