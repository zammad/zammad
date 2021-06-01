# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'KnowledgeBase loading initial data', type: :request, searchindex: true, authenticated_as: :current_user do
  include_context 'basic Knowledge Base' do
    before do
      draft_answer
      internal_answer
      published_answer
    end
  end

  before do
    post '/api/v1/knowledge_bases/init'
  end

  let(:current_user) { create(user_identifier) if defined?(user_identifier) }

  shared_examples 'returning valid JSON' do
    it { expect(response).to have_http_status(:ok) }
    it { expect(json_response).to be_a_kind_of(Hash) }
  end

  describe 'for admin' do
    let(:user_identifier) { :admin }

    it_behaves_like 'returning valid JSON'

    it 'returns assets for all KB objects' do
      expect(json_response).to include_assets_of(knowledge_base, category, draft_answer, internal_answer, published_answer)
    end
  end

  describe 'for agent' do
    let(:user_identifier) { :agent }

    it_behaves_like 'returning valid JSON'

    it 'returns assets for all KB objects except drafts' do
      expect(json_response)
        .to include_assets_of(knowledge_base, category, internal_answer, published_answer)
        .and not_include_assets_of(draft_answer)
    end
  end

  describe 'for customer' do
    let(:user_identifier) { :customer }

    it_behaves_like 'returning valid JSON'

    it 'only returns assets for KB itself' do
      expect(json_response)
        .to  include_assets_of(knowledge_base)
        .and not_include_assets_of(category, draft_answer, internal_answer, published_answer)
    end
  end

  describe 'for guests without authorization' do
    it { expect(response).to have_http_status(:forbidden) }
  end
end
