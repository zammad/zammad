# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

FactoryBot.define do
  factory :ai_agent, class: 'AI::Agent', aliases: %i[ai/agent] do
    name { Faker::Lorem.unique.sentence(word_count: 3) }

    created_by_id { 1 }
    updated_by_id { 1 }
  end
end
