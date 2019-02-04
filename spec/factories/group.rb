FactoryBot.define do
  factory :group do
    sequence(:name) { |n| "Group #{n}" }
    email_address
    created_by_id { 1 }
    updated_by_id { 1 }
  end
end
