FactoryBot.define do
  factory 'knowledge_base/menu_item', aliases: %i[knowledge_base_menu_item] do
    kb_locale { nil }
    title     { Faker::Kpop.iii_groups }
    url       { Faker::Internet.url }

    before :create do |menu_item|
      if menu_item.kb_locale.blank?
        kb = create(:knowledge_base)
        menu_item.kb_locale = kb.kb_locales.first
      end
    end
  end
end
