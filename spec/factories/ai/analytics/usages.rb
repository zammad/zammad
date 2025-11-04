# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

FactoryBot.define do
  factory :ai_analytics_usage, class: 'AI::Analytics::Usage' do
    ai_analytics_run
    user
  end
end
