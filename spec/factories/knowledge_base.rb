# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

FactoryBot.define do
  factory :knowledge_base do
    transient do
      given_kb_locale { nil }
    end
    iconset         { 'FontAwesome' }
    color_highlight { '#AAA' }
    color_header    { '#EEE' }
    homepage_layout { 'grid' }
    category_layout { 'list' }

    before :create do |kb, context|
      if context.given_kb_locale.present?
        kb.kb_locales << context.given_kb_locale
        context.given_kb_locale.knowledge_base = kb
      end

      if kb.kb_locales.blank?
        kb.kb_locales << build(:knowledge_base_locale, knowledge_base: kb, primary: true)
      end
    end
  end
end
