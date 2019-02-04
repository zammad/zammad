FactoryBot.define do
  factory :email_address do
    sequence(:email) { |n| "zammad#{n}@localhost.com" }
    sequence(:realname) { |n| "zammad#{n}" }
    channel       { create(:email_channel) }
    created_by_id 1
    updated_by_id 1
  end
end
