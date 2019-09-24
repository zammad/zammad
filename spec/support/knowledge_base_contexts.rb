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
    create(:knowledge_base_answer, category: category, published_at: 1.week.ago)
  end

  let :internal_answer do
    create(:knowledge_base_answer, category: category, internal_at: 1.week.ago)
  end
end
