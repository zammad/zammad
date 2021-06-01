# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

FactoryBot.define do
  factory 'knowledge_base/answer', aliases: %i[knowledge_base_answer] do
    transient do
      add_translation { true }
      translation_traits { [] }
      translation_attributes { {} }
      knowledge_base { nil }
    end

    category { create(:knowledge_base_category, { knowledge_base: knowledge_base }.compact) }

    before(:create) do |answer, context|
      next if answer.translations.present?

      answer.translations << build('knowledge_base/answer/translation', *context.translation_traits, answer: answer, **context.translation_attributes)
    end

    trait :draft # empty placeholder for better readability

    trait :internal do
      internal_at { 1.week.ago }
    end

    trait :published do
      published_at { 1.week.ago }
    end

    trait :archived do
      archived_at { 1.week.ago }
    end

    trait :with_video do
      transient do
        translation_traits { [:with_video] }
      end
    end

    trait :with_image do
      transient do
        translation_traits { [:with_image] }
      end
    end

    trait :with_attachment do
      transient do
        attachment { File.open('spec/fixtures/upload/hello_world.txt') }
      end

      after(:create) do |answer, context|
        Store.add(
          object:      answer.class.name,
          o_id:        answer.id,
          data:        context.attachment.read,
          filename:    File.basename(context.attachment.path),
          preferences: {}
        )
      end
    end
  end
end
