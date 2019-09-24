require 'rails_helper'

RSpec.describe 'KnowledgeBase loading initial data', type: :request, searchindex: true do
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

  shared_examples 'returning valid JSON' do
    it { expect(response).to have_http_status(:ok) }
    it { expect(json_response).to be_a_kind_of(Hash) }
  end

  describe 'for admin', authenticated_as: :admin_user do
    it_behaves_like 'returning valid JSON'

    it 'returns assets for all KB objects' do
      expect(json_response).to include_assets_of(knowledge_base, category, draft_answer, internal_answer, published_answer)
    end
  end

  describe 'for agent', authenticated_as: :agent_user do
    it_behaves_like 'returning valid JSON'

    it 'returns assets for all KB objects except drafts' do
      expect(json_response)
        .to include_assets_of(knowledge_base, category, internal_answer, published_answer)
        .and not_include_assets_of(draft_answer)
    end
  end

  describe 'for customer', authenticated_as: :customer_user do
    it_behaves_like 'returning valid JSON'

    it 'only returns assets for KB itself' do
      expect(json_response)
        .to  include_assets_of(knowledge_base)
        .and not_include_assets_of(category, draft_answer, internal_answer, published_answer)
    end
  end

  describe 'for guests without authorization' do
    it { expect(response).to have_http_status(:unauthorized) }
  end
end
