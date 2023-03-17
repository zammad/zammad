# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

FactoryBot.define do
  factory :authorization do
    uid      { Faker::Number.number(digits: 10) }
    user     { create(:customer) }
    provider { 'foo' }

    factory :twitter_authorization do
      provider { 'twitter' }
      username { Faker::Internet.username }
      user_id  { user.id }
    end
  end
end
