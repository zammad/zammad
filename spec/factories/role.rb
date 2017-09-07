FactoryGirl.define do
  sequence :test_role_name do |n|
    "TestRole#{n}"
  end
end

FactoryGirl.define do

  factory :role do
    name { generate(:test_role_name) }
    created_by_id 1
    updated_by_id 1
  end
end
