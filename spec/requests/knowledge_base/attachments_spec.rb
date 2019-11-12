require 'rails_helper'

RSpec.describe 'KnowledgeBase attachments', type: :request do
  include_context 'basic Knowledge Base'

  let(:attachment) do
    attachment_file = File.open 'spec/fixtures/upload/hello_world.txt'

    Store.add(
      object:        object.class.to_s,
      o_id:          object.id,
      data:          attachment_file.read,
      filename:      'hello_world.txt',
      preferences:   {},
      created_by_id: 1,
    )
  end

  let(:endpoint) { "/api/v1/attachments/#{attachment.id}" }

  describe 'visible when attached to' do
    shared_examples 'a visible resource' do
      it 'and returns correct status code' do
        get endpoint
        expect(response).to have_http_status(:ok)
      end
    end

    shared_examples 'a non-existent resource' do
      it 'and returns correct status code' do
        get endpoint
        expect(response).to have_http_status(:not_found)
      end
    end

    describe 'draft answer' do
      let(:object) { draft_answer }

      describe 'as agent', authenticated_as: :agent_user do
        it_behaves_like 'a non-existent resource'
      end

      context 'as admin', authenticated_as: :admin_user do
        it_behaves_like 'a visible resource'
      end

      context 'as customer', authenticated_as: :customer_user do
        it_behaves_like 'a non-existent resource'
      end

      context 'as guest' do
        it_behaves_like 'a non-existent resource'
      end
    end

    describe 'internal answer' do
      let(:object) { internal_answer }

      describe 'as agent', authenticated_as: :agent_user do
        it_behaves_like 'a visible resource'
      end

      context 'as admin', authenticated_as: :admin_user do
        it_behaves_like 'a visible resource'
      end

      context 'as customer', authenticated_as: :customer_user do
        it_behaves_like 'a non-existent resource'
      end

      context 'as guest' do
        it_behaves_like 'a non-existent resource'
      end
    end

    describe 'published answer' do
      let(:object) { published_answer }

      describe 'as agent', authenticated_as: :agent_user do
        it_behaves_like 'a visible resource'
      end

      context 'as admin', authenticated_as: :admin_user do
        it_behaves_like 'a visible resource'
      end

      context 'as customer', authenticated_as: :customer_user do
        it_behaves_like 'a visible resource'
      end

      context 'as guest' do
        it_behaves_like 'a visible resource'
      end
    end

    describe 'archived answer' do
      let(:object) { archived_answer }

      describe 'as agent', authenticated_as: :agent_user do
        it_behaves_like 'a non-existent resource'
      end

      context 'as admin', authenticated_as: :admin_user do
        it_behaves_like 'a visible resource'
      end

      context 'as customer', authenticated_as: :customer_user do
        it_behaves_like 'a non-existent resource'
      end

      context 'as guest' do
        it_behaves_like 'a non-existent resource'
      end
    end
  end

  describe 'deletable when attached to' do
    shared_examples 'a deletable resource' do
      it { expect { delete endpoint }.to change { Store.exists? attachment.id }.from(true).to(false) }
    end

    shared_examples 'a non-deletable resource' do
      it { expect { delete endpoint }.not_to change { Store.exists? attachment.id }.from(true) }
    end

    describe 'draft answer' do
      let(:object) { draft_answer }

      describe 'as agent', authenticated_as: :agent_user do
        it_behaves_like 'a non-deletable resource'
      end

      context 'as admin', authenticated_as: :admin_user do
        it_behaves_like 'a deletable resource'
      end

      context 'as customer', authenticated_as: :customer_user do
        it_behaves_like 'a non-deletable resource'
      end

      context 'as guest' do
        it_behaves_like 'a non-deletable resource'
      end
    end

    describe 'internal answer' do
      let(:object) { internal_answer }

      describe 'as agent', authenticated_as: :agent_user do
        it_behaves_like 'a non-deletable resource'
      end

      context 'as admin', authenticated_as: :admin_user do
        it_behaves_like 'a deletable resource'
      end

      context 'as customer', authenticated_as: :customer_user do
        it_behaves_like 'a non-deletable resource'
      end

      context 'as guest' do
        it_behaves_like 'a non-deletable resource'
      end
    end

    describe 'published answer' do
      let(:object) { published_answer }

      describe 'as agent', authenticated_as: :agent_user do
        it_behaves_like 'a non-deletable resource'
      end

      context 'as admin', authenticated_as: :admin_user do
        it_behaves_like 'a deletable resource'
      end

      context 'as customer', authenticated_as: :customer_user do
        it_behaves_like 'a non-deletable resource'
      end

      context 'as guest' do
        it_behaves_like 'a non-deletable resource'
      end
    end

    describe 'archived answer' do
      let(:object) { archived_answer }

      describe 'as agent', authenticated_as: :agent_user do
        it_behaves_like 'a non-deletable resource'
      end

      context 'as admin', authenticated_as: :admin_user do
        it_behaves_like 'a deletable resource'
      end

      context 'as customer', authenticated_as: :customer_user do
        it_behaves_like 'a non-deletable resource'
      end

      context 'as guest' do
        it_behaves_like 'a non-deletable resource'
      end
    end
  end
end
