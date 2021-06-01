# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

FactoryBot.define do
  factory 'knowledge_base/category/translation', aliases: %i[knowledge_base_category_translation] do
    transient do
      knowledge_base  { nil }
      parent_category { nil }
    end

    category         { nil }
    kb_locale        { nil }
    sequence(:title) { |n| "#{Faker::Appliance.brand} ##{n}" }

    before(:create) do |translation, context|
      if translation.category.nil?
        attrs = if context.parent_category
                  { parent: context.parent_category }
                elsif context.knowledge_base
                  { knowledge_base: context.knowledge_base }
                else
                  {}
                end

        attrs[:translations] = [translation]

        build(:knowledge_base_category, attrs)
      end

      translation.kb_locale = translation.category.knowledge_base.kb_locales.first if translation.kb_locale.nil?
    end
  end
end
