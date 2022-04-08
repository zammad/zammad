# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

FactoryBot.define do
  factory :role do
    sequence(:name) { |n| "TestRole#{n}" }
    created_by_id   { 1 }
    updated_by_id   { 1 }

    transient do
      permission_names { nil }
    end

    permissions { Permission.where(name: permission_names) }

    factory :agent_role do
      permissions { Permission.where(name: 'ticket.agent') }
    end

    trait :customer do
      permissions { Permission.where(name: 'ticket.customer') }
    end

    trait :admin do
      permissions { Permission.where(name: 'admin') }
    end

    trait :admin_core_workflow do
      permissions { Permission.where(name: 'admin.core_workflow') }
    end
  end
end
