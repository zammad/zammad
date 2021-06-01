# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

RSpec.shared_context 'basic Knowledge Base', current_user_id: 1 do
  let :knowledge_base do
    create(:knowledge_base)
  end

  let :primary_locale do
    knowledge_base.translation_primary.kb_locale
  end

  let :alternative_locale do
    create(:knowledge_base_locale, knowledge_base: knowledge_base, system_locale: Locale.find_by(locale: 'lt'))
  end

  let :category do
    create(:knowledge_base_category, knowledge_base: knowledge_base)
  end

  let :draft_answer do
    create(:knowledge_base_answer, category: category)
  end

  let :published_answer do
    create(:knowledge_base_answer, :published, :with_attachment, category: category)
  end

  let :published_answer_with_video do
    create(:knowledge_base_answer, :published, :with_video, category: category)
  end

  let :internal_answer do
    create(:knowledge_base_answer, :internal, category: category)
  end

  let :archived_answer do
    create(:knowledge_base_answer, :archived, category: category)
  end
end

RSpec.shared_context 'Knowledge Base menu items', current_user_id: 1 do
  let!(:menu_item_1) { create(:knowledge_base_menu_item, :for_header, kb_locale: primary_locale) }
  let!(:menu_item_2) { create(:knowledge_base_menu_item, :for_header, kb_locale: primary_locale) }
  let!(:menu_item_3) { create(:knowledge_base_menu_item, :for_footer, kb_locale: primary_locale) }
  let!(:menu_item_4) { create(:knowledge_base_menu_item, :for_footer, kb_locale: alternative_locale) }
  let!(:menu_item_5) { create(:knowledge_base_menu_item, :for_footer, kb_locale: alternative_locale) }
end
