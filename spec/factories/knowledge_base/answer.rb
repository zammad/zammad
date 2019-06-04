FactoryBot.define do
  factory 'knowledge_base/answer', aliases: %i[knowledge_base_answer] do
    category { create(:knowledge_base_category) }
  end
end
