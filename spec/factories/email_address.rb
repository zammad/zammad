FactoryBot.define do
  factory :email_address do
    sequence(:email) { |n| "zammad#{n}@localhost.com" }
    sequence(:realname) { |n| "zammad#{n}" }
    channel_id    1
    created_by_id 1
    updated_by_id 1
  end
end
