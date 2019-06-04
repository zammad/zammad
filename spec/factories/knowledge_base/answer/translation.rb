FactoryBot.define do
  factory 'knowledge_base/answer/translation', aliases: %i[knowledge_base_answer_translation] do
    answer    { nil }
    kb_locale { nil }
    title     { Faker::Appliance.equipment }
    content   { build(:knowledge_base_answer_translation_content) }

    before(:create) do |translation|
      if translation.answer.nil? && translation.kb_locale.nil?
        translation.answer = create(:knowledge_base_answer)
        translation.kb_locale = translation.answer.category.knowledge_base.kb_locales.first
      end
    end
  end
end
