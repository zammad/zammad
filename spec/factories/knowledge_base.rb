# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

FactoryBot.define do
  factory :knowledge_base do
    transient do
      given_kb_locale { nil }
    end
    iconset         { 'FontAwesome' }
    color_highlight { '#AAA' }
    color_header    { '#EEE' }
    color_header_link { '#FFF000' }
    homepage_layout { 'grid' }
    category_layout { 'list' }

    # Pinned against the product default (KnowledgeBase::DEFAULT_SORTING_MODE), the way the layouts
    # and colors above are: the suite is full of examples about hand-arranged order, and they read
    # as what they are only when the list they set up is actually in `manual`. Examples about the
    # default itself build their records without the factory.
    category_sorting_mode { 'manual' }

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
