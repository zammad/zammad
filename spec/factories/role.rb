FactoryBot.define do
  factory :role do
    sequence(:name) { |n| "TestRole#{n}" }
    created_by_id   { 1 }
    updated_by_id   { 1 }

    factory :agent_role do
      permissions { Permission.where(name: 'ticket.agent') }
    end
  end
end
