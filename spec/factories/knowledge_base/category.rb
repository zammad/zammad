# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

FactoryBot.define do
  factory 'knowledge_base/category', aliases: %i[knowledge_base_category] do
    transient do
      add_translation { true }
    end

    knowledge_base { parent&.knowledge_base || create(:knowledge_base) }
    category_icon  { 'f04b' }

    before(:create) do |category|
      next if category.translations.present?

      category.translations << create('knowledge_base/category/translation', category: category)
    end

    trait :empty # empty placeholder for better readability

    %i[published internal draft archived].each do |state|
      trait "containing_#{state}" do
        after(:create) do |obj|
          create(:knowledge_base_answer, state, parent: obj)

          obj.reload
        end
      end
    end
  end

  factory 'kb_category_with_tree', parent: 'knowledge_base/category' do
    after(:create) do |obj|
      create(:knowledge_base_category, parent: obj)

      level2 = create(:knowledge_base_category, parent: obj)
      create_list(:knowledge_base_category, 2, parent: level2)

      level3 = level2.children.reload.first
      create_list(:knowledge_base_category, 2, parent: level3)

      obj.reload
    end
  end
end
