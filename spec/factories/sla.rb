# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

FactoryBot.define do
  factory :sla do
    calendar
    sequence(:name) { |n| "SLA #{n}" }
    created_by_id   { 1 }
    updated_by_id   { 1 }

    condition do
      {
        'ticket.state_id' => {
          operator: 'is',
          value:    Ticket::State.by_category(:open).pluck(:id),
        },
      }
    end

    trait :condition_blank do
      condition do
        {}
      end
    end

    trait :condition_title do
      transient do
        condition_title { nil }
      end

      condition do
        {
          'ticket.title' => {
            operator: 'contains',
            value:    condition_title
          }
        }
      end
    end
  end
end
