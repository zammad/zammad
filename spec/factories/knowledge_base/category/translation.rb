FactoryBot.define do
  factory 'knowledge_base/category/translation', aliases: %i[knowledge_base_category_translation] do
    category  { nil }
    kb_locale { nil }
    title     { Faker::Appliance.brand }

    before(:create) do |translation|
      if translation.category.nil? && translation.kb_locale.nil?
        translation.category = create(:knowledge_base_category)
        translation.kb_locale = translation.category.knowledge_base.kb_locales.first
      end
    end
  end
end
