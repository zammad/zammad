# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

FactoryBot.define do
  factory :ai_agent, class: 'AI::Agent', aliases: %i[ai/agent] do
    sequence(:name) { |n| "AI Agent #{n}" }

    created_by_id { 1 }
    updated_by_id { 1 }
  end
end
