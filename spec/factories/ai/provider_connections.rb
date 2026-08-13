# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

FactoryBot.define do
  factory :ai_provider_connection, class: 'AI::ProviderConnection', aliases: %i[ai/provider_connection] do
    sequence(:name) { |n| "connection-#{n}" }
    provider        { 'open_ai' }
    config          { { token: 'secret-token', model: 'gpt-4o' } }

    trait :default_chat do
      default_chat { true }
    end

    # A connection serving embeddings has to name its model, so the trait brings one - an explicit
    # `config` still has to carry it, since it replaces this one rather than merging into it.
    trait :default_embedding do
      default_embedding { true }
      config            { { token: 'secret-token', model: 'gpt-4o', embedding_model: 'text-embedding-3-small' } }
    end

    trait :default_ocr do
      default_ocr { true }
    end
  end
end
