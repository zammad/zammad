# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'KnowledgeBase visible ids', authenticated_as: :current_user, type: :request do
  include_context 'basic Knowledge Base'

  let(:current_user) { create(:admin) }

  before do
    published_answer

    get '/api/v1/knowledge_bases/visible_ids'
  end

  it 'lists the answer and its category', :aggregate_failures do
    expect(json_response['answer_ids']).to include(published_answer.id)
    expect(json_response['category_ids']).to include(category.id)
  end

  # https://github.com/zammad/zammad/issues/6338
  context 'when the knowledge base is inactive' do
    before do
      knowledge_base.update! active: false

      get '/api/v1/knowledge_bases/visible_ids'
    end

    it 'lists nothing at all' do
      expect(json_response).to be_empty
    end
  end
end
