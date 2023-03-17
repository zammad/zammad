# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

FactoryBot.define do
  factory :trigger do
    sequence(:name) { |n| "Test trigger #{n}"  }
    condition       { { 'ticket.state_id' => { 'operator' => 'is not', 'value' => 4 } } }
    perform         { { 'ticket.state_id' => { 'value' => 4 } } }
    active          { true }
    created_by_id   { 1 }
    updated_by_id   { 1 }

    trait :conditionable do
      transient do
        condition_ticket_action { nil }
      end

      condition { {} }

      callback(:after_stub, :before_create) do |object, context|
        hash = object.condition

        hash['ticket.action'] = { 'operator' => 'is', 'value' => context.condition_ticket_action.to_s } if context.condition_ticket_action

        object.condition = hash
      end
    end

    # empty trigger to help to test atomically
    trait :no_perform do
      perform { { null: true } }
    end
  end
end
