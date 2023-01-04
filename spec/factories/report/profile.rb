# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

FactoryBot.define do
  factory :'report/profile', aliases: %i[report_profile] do
    sequence(:name) { |n| "Report #{n}" }
    active { true }
    created_by_id   { 1 }
    updated_by_id   { 1 }

    trait :condition_created_at do
      transient do
        ticket_created_at { nil }
      end

      condition do
        {
          'ticket.created_at' => {
            operator: 'before (absolute)',
            value:    ticket_created_at.iso8601
          }
        }
      end
    end
  end
end
