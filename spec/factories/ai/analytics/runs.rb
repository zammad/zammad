# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

FactoryBot.define do
  factory :ai_analytics_run, class: 'AI::Analytics::Run' do
    identifier      { SecureRandom.uuid }
    ai_service_name { 'TestService' }

    trait :with_error do
      error do
        { message: 'some error' }
      end
    end
  end
end
