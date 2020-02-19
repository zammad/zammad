FactoryBot.define do
  factory 'knowledge_base/answer', aliases: %i[knowledge_base_answer] do
    transient do
      add_translation { true }
      translation_traits { [] }
    end

    category { create(:knowledge_base_category) }

    before(:create) do |answer, context|
      next if answer.translations.present?

      answer.translations << build('knowledge_base/answer/translation', *context.translation_traits, answer: answer)
    end

    trait :with_video do
      transient do
        translation_traits { [:with_video] }
      end
    end
  end
end
