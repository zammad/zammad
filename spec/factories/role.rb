# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

FactoryBot.define do
  factory :role do
    sequence(:name) { |n| "TestRole#{n}" }
    created_by_id   { 1 }
    updated_by_id   { 1 }

    transient do
      permission_names { nil }
    end

    permissions { Permission.where(name: permission_names) }

    trait :agent do
      permission_names { 'ticket.agent' }
    end

    trait :customer do
      permission_names { 'ticket.customer' }
    end

    trait :admin do
      permission_names { 'admin' }
    end

    trait :admin_core_workflow do
      permission_names { 'admin.core_workflow' }
    end
  end
end
