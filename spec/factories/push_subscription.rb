# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

FactoryBot.define do
  factory :push_subscription do
    user
    sequence(:endpoint) { |n| "https://fcm.googleapis.com/fcm/send/#{n}" }
    p256dh              { Base64.urlsafe_encode64(SecureRandom.random_bytes(65), padding: false) }
    auth                { Base64.urlsafe_encode64(SecureRandom.random_bytes(16), padding: false) }
  end
end
