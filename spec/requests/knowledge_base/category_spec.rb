# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'KnowledgeBase category', authenticated_as: :editor, type: :request do
  let(:editor) { create(:admin) }

  include_context 'basic Knowledge Base'

  describe '#create' do
    subject(:create_category) do
      post "/api/v1/knowledge_bases/#{knowledge_base.id}/categories", params: params, as: :json

      json_response
    end

    let(:parent_id) { nil }
    let(:params) do
      {
        knowledge_base_id:       knowledge_base.id,
        parent_id:               parent_id,
        category_icon:           'f1ad',
        translations_attributes: [{ kb_locale_id: primary_locale.id, title: 'Fresh category' }],
      }
    end

    before { knowledge_base }

    # This interface has no service behind it and submits no sorting mode either — its
    #   AGENT_ALLOWED_ATTRIBUTES list does not even carry the two columns — so the model's
    #   create-time inheritance is the only thing that fills them, for both stacks alike
    #   (KnowledgeBase::Category#inherit_sorting_modes).
    context 'when created below a parent category' do
      let(:parent_id) { category.id }

      before { category.update!(category_sorting_mode: 'last_update', answer_sorting_mode: 'manual') }

      it 'follows the sorting modes of the parent, per list' do
        expect(create_category)
          .to include('category_sorting_mode' => 'last_update', 'answer_sorting_mode' => 'manual')
      end
    end

    # The root lists categories only, so there is no answer mode above a top level category to
    #   inherit.
    context 'when created at the top level' do
      before { knowledge_base.update!(category_sorting_mode: 'last_update') }

      it 'takes the knowledge base category mode and the default answer mode' do
        expect(create_category)
          .to include('category_sorting_mode' => 'last_update', 'answer_sorting_mode' => KnowledgeBase::DEFAULT_SORTING_MODE)
      end
    end
  end
end
