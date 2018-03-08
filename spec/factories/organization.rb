FactoryBot.define do
  sequence :test_organization_name do |n|
    "TestOrganization#{n}"
  end
end

FactoryBot.define do

  factory :organization do
    name { generate(:test_organization_name) }
    shared true
    domain ''
    domain_assignment false
    active true
    note ''
    created_by_id 1
    updated_by_id 1
  end
end
