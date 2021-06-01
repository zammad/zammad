# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

FactoryBot.define do
  factory 'knowledge_base/menu_item', aliases: %i[knowledge_base_menu_item] do
    kb_locale        { nil }
    sequence(:title) { |n| "menu_#{n}" }
    url              { Faker::Internet.url }

    for_header

    before :create do |menu_item|
      if menu_item.kb_locale.blank?
        kb = create(:knowledge_base)
        menu_item.kb_locale = kb.kb_locales.first
      end
    end

    trait :for_footer do
      location { 'footer' }
    end

    trait :for_header do
      location { 'header' }
    end
  end
end
