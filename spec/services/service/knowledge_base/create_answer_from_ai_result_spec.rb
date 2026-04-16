# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::KnowledgeBase::CreateAnswerFromAIResult do
  subject(:service) do
    described_class.new(
      ai_result:,
      knowledge_base:,
      kb_locale:,
      current_user_id: current_user.id
    )
  end

  let(:current_user)     { create(:agent) }
  let(:knowledge_base)   { create(:knowledge_base) }
  let!(:first_category)  { create(:knowledge_base_category, knowledge_base: knowledge_base) }
  let!(:second_category) { create(:knowledge_base_category, knowledge_base: knowledge_base) }
  let(:kb_locale)        { knowledge_base.kb_locales.find_by(primary: true) || knowledge_base.kb_locales.first }

  describe '#execute' do
    context 'when ai result contains full payload' do
      let(:ai_result) do
        {
          title:       'Reset a locked account',
          category_id: second_category.id,
          body:        'The customer cannot sign in after too many failed attempts.',
        }
      end

      it 'creates a draft answer using the expected values', :aggregate_failures do
        kb_answer = service.execute
        translation = kb_answer.translations.find_by(kb_locale: kb_locale)

        expect(kb_answer).to be_persisted
        expect(kb_answer.category_id).to eq(second_category.id)
        expect(kb_answer.promoted).to be(false)
        expect(translation.title).to eq('Reset a locked account')
        expect(translation.content.body).to include('The customer cannot sign in after too many failed attempts.')
      end

      it 'adds the ai-generated tag to the answer' do
        kb_answer = service.execute

        expect(kb_answer.tag_list).to include('ai-generated')
      end

      it 'appends a translated AI disclaimer note to the body' do
        kb_answer = service.execute
        translation = kb_answer.translations.find_by(kb_locale: kb_locale)

        expect(translation.content.body).to include('<p><br><small><em>Be sure to check AI-generated content for accuracy.</em></small></p>')
      end
    end

    context 'when category id is invalid' do
      let(:ai_result) do
        {
          category_id: -1,
          title:       'Some title',
          body:        'Some body',
        }
      end

      it 'raises an error' do
        expect { service.execute }.to raise_error(Exceptions::UnprocessableEntity, 'No valid knowledge base category provided.')
      end
    end

    context 'when title is blank' do
      let(:ai_result) do
        {
          category_id: first_category.id,
          title:       '   ',
        }
      end

      it 'raises an error' do
        expect { service.execute }.to raise_error(StandardError)
      end
    end

    context 'when title is longer than 250 characters' do
      let(:long_title) { 'a' * 300 }
      let(:ai_result) { { title: long_title, category_id: first_category.id } }

      it 'truncates title to 250 characters' do
        kb_answer = service.execute
        translation = kb_answer.translations.find_by(kb_locale: kb_locale)

        expect(translation.title).to eq(long_title.truncate(250))
      end
    end

    context 'when title already exists in the same category' do
      let(:ai_result) do
        {
          title:       'Reset a locked account',
          category_id: first_category.id,
          body:        'Some body',
        }
      end

      before do
        create(:knowledge_base_answer,
               category:               first_category,
               translation_attributes: { title: 'Reset a locked account', kb_locale: kb_locale })
      end

      it 'appends a duplicate suffix to the title' do
        kb_answer = service.execute
        translation = kb_answer.translations.find_by(kb_locale: kb_locale)

        expect(translation.title).to match(%r{^Reset a locked account \(Duplicate [a-zA-Z0-9]{4}\)$})
      end
    end

    context 'when kb locale is missing' do
      let(:ai_result) { {} }
      let(:kb_locale) { nil }

      it 'raises an error' do
        expect { service.execute }.to raise_error(Exceptions::UnprocessableEntity, 'No knowledge base locale configured.')
      end
    end

  end
end
