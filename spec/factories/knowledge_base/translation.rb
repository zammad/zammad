# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

FactoryBot.define do
  factory 'knowledge_base/translation', aliases: %i[knowledge_base_translation] do
    knowledge_base { kb_locale.knowledge_base }
    kb_locale      { nil }
    title          { Faker::Company.name }
    footer_note    { 'footer' }
  end
end
