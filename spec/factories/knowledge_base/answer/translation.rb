# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

FactoryBot.define do
  factory 'knowledge_base/answer/translation', aliases: %i[knowledge_base_answer_translation] do
    created_by_id    { 1 }
    updated_by_id    { 1 }
    answer           { nil }
    kb_locale        { nil }
    sequence(:title) { |n| "#{Faker::Appliance.equipment} ##{n}" }
    content factory: %i[knowledge_base_answer_translation_content], strategy: :build

    before(:create) do |translation, _context|
      if translation.answer.nil?
        build(:knowledge_base_answer, translations: [translation])
      end

      if translation.kb_locale.nil?
        translation.kb_locale = translation.answer.category.knowledge_base.kb_locales.first
      end
    end

    after(:build) do |translation, _context|
      if translation.answer.nil?
        build(:knowledge_base_answer, translations: [translation])
      end

      if translation.kb_locale.nil?
        translation.kb_locale = translation.answer.category.knowledge_base.kb_locales.first
      end
    end

    trait :with_video do
      content factory: %i[knowledge_base_answer_translation_content with_video], strategy: :build
    end

    trait :with_image do
      content factory: %i[knowledge_base_answer_translation_content with_image], strategy: :build
    end
  end
end
