# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'KnowledgeBase public answers', type: :request do
  include_context 'basic Knowledge Base'

  describe '#show' do
    context 'when visitor is a guest' do
      it 'returns OK for published answer' do
        get help_answer_path(locale_name, category, published_answer)
        expect(response).to have_http_status :ok
      end

      it 'returns NOT FOUND for draft answer' do
        get help_answer_path(locale_name, category, draft_answer)
        expect(response).to have_http_status :not_found
      end
    end

    context 'when visitor is an editor' do
      before do
        published_answer && draft_answer
        authenticated_as(create(:admin), via: :browser)
      end

      it 'returns OK for published answer' do
        get help_answer_path(locale_name, category, published_answer)
        expect(response).to have_http_status :ok
      end

      it 'returns OK for draft answer' do
        get help_answer_path(locale_name, category, draft_answer)
        expect(response).to have_http_status :ok
      end
    end
  end
end
