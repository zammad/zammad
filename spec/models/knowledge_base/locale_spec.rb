# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe KnowledgeBase::Locale, type: :model do
  subject(:kb_locale) { create(:knowledge_base_locale) }

  describe 'destroying' do
    include_context 'basic Knowledge Base'

    it 'destroys locale' do
      published_answer # populate locale

      expect { primary_locale.destroy! }
        .not_to raise_error
    end
  end

  describe '.available_for' do
    include_context 'basic Knowledge Base'

    it 'lists the locales the object is translated to' do
      create(:knowledge_base_answer_translation, answer: published_answer, kb_locale: alternative_locale)

      expect(described_class.available_for(published_answer)).to contain_exactly(primary_locale, alternative_locale)
    end

    it 'lists the locales a category holds published content in, translated or not' do
      create(:knowledge_base_answer_translation, answer: published_answer_in_subcategory, kb_locale: alternative_locale)

      expect(described_class.available_for(category)).to contain_exactly(primary_locale, alternative_locale)
    end

    it 'does not count unpublished content' do
      create(:knowledge_base_answer_translation, answer: draft_answer, kb_locale: alternative_locale)

      expect(described_class.available_for(category)).to contain_exactly(primary_locale)
    end

    it 'lists the locales a knowledge base holds published content in, translated or not' do
      create(:knowledge_base_answer_translation, answer: published_answer_in_subcategory, kb_locale: alternative_locale)

      expect(described_class.available_for(knowledge_base)).to contain_exactly(primary_locale, alternative_locale)
    end
  end

  describe 'audit log' do
    before { Setting.set('system_init_done', true) }

    let(:audit_logs) { AuditLog.where(auditable_type: described_class.name) }

    context 'when locale is added' do
      it 'creates an audit log record' do
        expect { kb_locale }.to change(audit_logs.where(action_type: 'create'), :count).by(1)
      end

      it 'records the system locale as auditable name' do
        expect(audit_logs.find_by(action_type: 'create', auditable_id: kb_locale.id).auditable_name)
          .to eq(kb_locale.system_locale.locale)
      end
    end

    context 'when locale is removed' do
      it 'creates an audit log record' do
        kb_locale

        expect { kb_locale.destroy! }
          .to change(audit_logs.where(action_type: 'destroy', auditable_id: kb_locale.id), :count).by(1)
      end
    end

    context 'when locale is removed via nested attributes' do
      let(:knowledge_base) { create(:knowledge_base) }
      let(:secondary_system_locale) do
        Locale.where.not(id: knowledge_base.kb_locales.select(:system_locale_id)).first ||
          create(:locale, locale: 'en-us', name: 'English (United States)')
      end
      let(:secondary_locale) do
        create(:knowledge_base_locale, knowledge_base: knowledge_base, system_locale: secondary_system_locale)
      end

      it 'creates an audit log record' do
        secondary_locale

        expect { knowledge_base.update!(kb_locales_attributes: [{ id: secondary_locale.id, _destroy: true }]) }
          .to change(audit_logs.where(action_type: 'destroy', auditable_id: secondary_locale.id), :count).by(1)
      end
    end
  end
end
