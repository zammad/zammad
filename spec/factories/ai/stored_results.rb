# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

FactoryBot.define do
  factory :ai_stored_result, class: 'AI::StoredResult' do
    identifier { SecureRandom.uuid }
    locale     { Locale.first }
  end
end
