# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

FactoryBot.define do
  factory :ai_text_tool, class: 'AI::TextTool', aliases: %i[ai/text_tool] do
    name { Faker::Lorem.unique.sentence(word_count: 3) }

    instruction { Faker::Lorem.paragraph(sentence_count: 3) }

    created_by_id { 1 }
    updated_by_id { 1 }
  end
end
