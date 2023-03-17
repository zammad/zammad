# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

FactoryBot.define do
  factory :user_device do
    user_id                { 1 }
    name                   { 'test 1' }
    location               { 'some location' }
    user_agent             { 'some user agent' }
    ip                     { '127.0.0.1' }
    sequence(:fingerprint) { |n| "fingerprint#{n}" }
  end
end
