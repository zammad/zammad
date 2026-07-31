# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

FactoryBot.define do
  factory :ai_feature_provider, class: 'AI::FeatureProvider', aliases: %i[ai/feature_provider] do
    identifier { 'ticket_summarize' }
    options    { {} }

    provider_connection factory: %i[ai_provider_connection]
  end
end
