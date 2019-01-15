FactoryBot.define do
  sequence :test_role_name do |n|
    "TestRole#{n}"
  end
end

FactoryBot.define do
  factory :role do
    name { generate(:test_role_name) }
    created_by_id 1
    updated_by_id 1

    factory :agent_role do
      permissions { Permission.where(name: 'ticket.agent') }
    end
  end
end
