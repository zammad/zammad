# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

FactoryBot.define do
  factory :ai_provider_connection, class: 'AI::ProviderConnection', aliases: %i[ai/provider_connection] do
    sequence(:name) { |n| "connection-#{n}" }
    provider        { 'open_ai' }
    config          { { token: 'secret-token', model: 'gpt-4o' } }

    trait :default_chat do
      default_chat { true }
    end

    trait :default_embedding do
      default_embedding { true }
    end

    trait :default_ocr do
      default_ocr { true }
    end
  end
end
