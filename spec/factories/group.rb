FactoryBot.define do
  factory :group do
    email_address
    sequence(:name) { |n| "Group #{n}" }
    created_by_id   { 1 }
    updated_by_id   { 1 }
  end
end
