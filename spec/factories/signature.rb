FactoryGirl.define do
  sequence :test_signature_name do |n|
    "Test signature #{n}"
  end
end

FactoryGirl.define do
  factory :signature do
    name { generate(:test_signature_name) }
    body '#{user.firstname} #{user.lastname}'.text2html
    created_by_id 1
    updated_by_id 1
  end
end
