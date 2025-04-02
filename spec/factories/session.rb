# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

FactoryBot.define do
  factory :session do
    session_id  { SecureRandom.urlsafe_base64(64) }
    data        { { 'persistent' => true } }
  end
end
