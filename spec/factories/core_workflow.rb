# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

FactoryBot.define do
  factory :core_workflow do
    sequence(:name) { |n| "test - workflow #{format '%07d', n}" }
    changeable { false }
    created_by_id { 1 }
    updated_by_id { 1 }

    trait :active_and_screen do
      transient do
        screen { 'edit' }
      end

      preferences { { screen: screen } }
      active      { true }
    end

    trait :condition_group do
      transient do
        group { nil }
      end

      condition_saved do
        { 'ticket.group_id': { operator: 'is', value: group.id.to_s } }
      end
    end

    trait :perform_action do
      transient do
        object_name { 'Ticket' }
        key         { 'ticket.priority_id' }
        operator    { 'remove_option' }
        value       { '3' }
      end

      perform do
        { key => { operator: operator, operator => value } }
      end

      object { object_name }
    end
  end
end
