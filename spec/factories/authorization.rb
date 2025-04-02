# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

FactoryBot.define do
  factory :authorization do
    uid      { Faker::Number.unique.number(digits: 10) }
    user     factory: :customer
    provider { 'foo' }

    factory :twitter_authorization do
      provider { 'twitter' }
      username { Faker::Internet.username }
      user_id  { user.id }
    end
  end
end
