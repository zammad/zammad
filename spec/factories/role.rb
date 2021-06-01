# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

FactoryBot.define do
  factory :role do
    sequence(:name) { |n| "TestRole#{n}" }
    created_by_id   { 1 }
    updated_by_id   { 1 }

    factory :agent_role do
      permissions { Permission.where(name: 'ticket.agent') }
    end

    trait :customer do
      permissions { Permission.where(name: 'ticket.customer') }
    end

    trait :admin do
      permissions { Permission.where(name: 'admin') }
    end
  end
end
