require 'rails_helper'

RSpec.describe 'KnowledgeBase translation update', type: :request, authentication: true do
  include_context 'basic Knowledge Base'

  let(:new_title) { 'new title for update test' }

  let(:params_for_updating) do
    {
      "translations_attributes": [
        {
          "title":       new_title,
          "footer_note": 'new footer',
          "id":          knowledge_base.kb_locales.first.id
        }
      ]
    }
  end

  let(:request) do
    patch "/api/v1/knowledge_bases/#{knowledge_base.id}?full=true", params: params_for_updating, as: :json
  end

  describe 'changes KB translation title' do
    describe 'as editor', authenticated_as: :admin_user do
      it 'updates title' do
        expect { request }.to change { knowledge_base.reload.translations.first.title }.to(new_title)
      end
    end

    describe 'as reader', authenticated_as: :agent_user do
      it 'does not change title' do
        expect { request }.not_to change { knowledge_base.reload.translations.first.title }
      end
    end

    describe 'as non-KB user', authenticated_as: :customer do
      it 'does not change title' do
        expect { request }.not_to change { knowledge_base.reload.translations.first.title }
      end
    end

    describe 'as a guest' do
      it 'does not change title' do
        expect { request }.not_to change { knowledge_base.reload.translations.first.title }
      end
    end
  end

  describe 'can make request to KB translation' do
    before { request }

    describe 'as editor', authenticated_as: :admin_user do
      it { expect(response).to have_http_status(:ok) }
      it { expect(json_response).to be_a_kind_of(Hash) }
    end

    describe 'as reader', authenticated_as: :agent_user do
      it { expect(response).to have_http_status(:unauthorized) }
    end

    describe 'as non-KB user', authenticated_as: :customer do
      it { expect(response).to have_http_status(:unauthorized) }
    end

    describe 'as a guest' do
      it { expect(response).to have_http_status(:unauthorized) }
    end
  end
end
