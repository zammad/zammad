FactoryBot.define do
  factory 'knowledge_base/answer', aliases: %i[knowledge_base_answer] do
    category { create(:knowledge_base_category) }

    before(:create) do |answer|
      next if answer.translations.present?

      answer.translations << build('knowledge_base/answer/translation', answer: answer)
    end
  end
end
