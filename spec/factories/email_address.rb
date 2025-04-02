# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

FactoryBot.define do
  factory :email_address do
    channel factory: %i[email_channel]
    sequence(:email) { |n| "zammad#{n}@localhost.com" }
    sequence(:name)  { |n| "zammad#{n}" }
    active           { true }
    created_by_id    { 1 }
    updated_by_id    { 1 }
  end
end
