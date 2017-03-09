FactoryGirl.define do
  sequence :test_group_name do |n|
    "TestGroup#{n}"
  end
end

FactoryGirl.define do

  factory :group do
    name { generate(:test_group_name) }
    created_by_id 1
    updated_by_id 1
  end
end
