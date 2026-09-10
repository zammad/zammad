# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# Deactivating a role revokes the knowledge base access it granted. The REST endpoints below are
#   gated by the object policies alone: Controllers::KnowledgeBase::AnswersControllerPolicy and
#   CategoriesControllerPolicy give every one of these actions its own predicate, and each of those
#   predicates resolves access through KnowledgeBasePolicy, KnowledgeBase::CategoryPolicy or
#   KnowledgeBase::AnswerPolicy. No permission name stands behind them either — neither controller
#   policy declares a `default_permit!`, so an action without a predicate would find nothing in
#   Controllers::ApplicationControllerPolicy#method_missing and raise rather than fall through to a
#   permissive default.
#
# Covers the whole of that surface rather than the reported case alone — reads, writes, deletes,
#   list ordering and publication state changes, across all three object policies
#   (KnowledgeBasePolicy, and the category and answer ones) — because a single unfiltered role
#   list is what backs every one of them, and any of these predicates could be changed
#   independently of the others.
#
# Asserted here rather than on the policies, because the policy specs stub the resolved access
#   (see the 'with KB policy check' shared examples) and would pass either way.
RSpec.describe 'KnowledgeBase access via a deactivated role', authenticated_as: :user, type: :request do
  include_context 'basic Knowledge Base'

  let(:granting_role_active) { false }
  let(:granting_role)        { create(:role, permission_names: 'knowledge_base.editor', active: granting_role_active) }

  # Without a second role the user holds no permission at all and cannot use the API to begin with,
  #   so the deactivated role would not be what the assertions turn on.
  let(:agent_role) { create(:role, permission_names: 'ticket.agent') }
  let(:user)       { create(:user, roles: [agent_role, granting_role]) }

  # The control case rules out a spec that never exercised the path: with the very same role active,
  #   every request below is authorized.
  shared_examples 'an action the deactivated role must not authorize' do |authorized_status:|
    context 'when the granting role is active' do
      let(:granting_role_active) { true }

      it "responds with #{authorized_status}" do
        expect(perform_request).to have_http_status(authorized_status)
      end
    end

    context 'when the granting role is deactivated' do
      it 'responds with forbidden' do
        expect(perform_request).to have_http_status(:forbidden)
      end
    end
  end

  describe 'GET /answers/:id' do
    subject(:perform_request) do
      get "/api/v1/knowledge_bases/#{knowledge_base.id}/answers/#{internal_answer.id}", as: :json

      response
    end

    include_examples 'an action the deactivated role must not authorize', authorized_status: :ok
  end

  describe 'PUT /answers/:id' do
    subject(:perform_request) do
      put "/api/v1/knowledge_bases/#{knowledge_base.id}/answers/#{internal_answer.id}",
          params: { category_id: category.id, internal_note: 'via deactivated role' }, as: :json

      response
    end

    include_examples 'an action the deactivated role must not authorize', authorized_status: :ok
  end

  describe 'DELETE /answers/:id' do
    subject(:perform_request) do
      delete "/api/v1/knowledge_bases/#{knowledge_base.id}/answers/#{internal_answer.id}", as: :json

      response
    end

    include_examples 'an action the deactivated role must not authorize', authorized_status: :ok

    # The report found the destroy not merely authorized but carried out, so the status alone is
    #   not the whole assertion.
    it 'keeps the answer' do
      internal_answer

      expect { perform_request }.not_to change(KnowledgeBase::Answer, :count)
    end
  end

  describe 'GET /categories/:id' do
    subject(:perform_request) do
      get "/api/v1/knowledge_bases/#{knowledge_base.id}/categories/#{category.id}", as: :json

      response
    end

    before { internal_answer }

    include_examples 'an action the deactivated role must not authorize', authorized_status: :ok
  end

  describe 'PUT /categories/:id' do
    subject(:perform_request) do
      put "/api/v1/knowledge_bases/#{knowledge_base.id}/categories/#{category.id}",
          params: { category_icon: 'f1ad' }, as: :json

      response
    end

    include_examples 'an action the deactivated role must not authorize', authorized_status: :ok
  end

  # Creating a top level category and ordering the root list both resolve their access against the
  #   knowledge base rather than a category, i.e. through KnowledgeBasePolicy — the third policy
  #   built on the same role list.
  describe 'POST /categories at the top level' do
    subject(:perform_request) do
      post "/api/v1/knowledge_bases/#{knowledge_base.id}/categories",
           params: {
             knowledge_base_id:       knowledge_base.id,
             category_icon:           'f1ad',
             translations_attributes: [{ kb_locale_id: primary_locale.id, title: 'Fresh category' }],
           }, as: :json

      response
    end

    include_examples 'an action the deactivated role must not authorize', authorized_status: :created
  end

  describe 'PATCH /categories/reorder_root_categories' do
    subject(:perform_request) do
      patch "/api/v1/knowledge_bases/#{knowledge_base.id}/categories/reorder_root_categories",
            params: { sorting_mode: 'manual', ordered_ids: [other_category.id, category.id] }, as: :json

      response
    end

    before { category && other_category }

    include_examples 'an action the deactivated role must not authorize', authorized_status: :ok
  end

  describe 'DELETE /categories/:id' do
    subject(:perform_request) do
      delete "/api/v1/knowledge_bases/#{knowledge_base.id}/categories/#{other_category.id}", as: :json

      response
    end

    include_examples 'an action the deactivated role must not authorize', authorized_status: :ok

    it 'keeps the category' do
      other_category

      expect { perform_request }.not_to change(KnowledgeBase::Category, :count)
    end
  end

  # Ordering a list writes a column of the node the list belongs to, so both actions resolve
  #   through KnowledgeBase::CategoryPolicy#update? on that node rather than through the policy's
  #   own #update?.
  describe 'PATCH /categories/:id/reorder_categories' do
    subject(:perform_request) do
      patch "/api/v1/knowledge_bases/#{knowledge_base.id}/categories/#{category.id}/reorder_categories",
            params: { sorting_mode: 'manual', ordered_ids: [subcategory.id] }, as: :json

      response
    end

    before { subcategory }

    include_examples 'an action the deactivated role must not authorize', authorized_status: :ok
  end

  describe 'PATCH /categories/:id/reorder_answers' do
    subject(:perform_request) do
      patch "/api/v1/knowledge_bases/#{knowledge_base.id}/categories/#{category.id}/reorder_answers",
            params: { sorting_mode: 'manual', ordered_ids: [internal_answer.id] }, as: :json

      response
    end

    before { internal_answer }

    include_examples 'an action the deactivated role must not authorize', authorized_status: :ok
  end

  # The `has_publishing` route concern generates one action per state machine event, and
  #   Controllers::KnowledgeBase::AnswersControllerPolicy derives every one of them from
  #   KnowledgeBase::AnswerPolicy#update? — so a publication state change resolves through the same
  #   role list as an ordinary answer update. Called out in the issue triage as the surface that
  #   the fix for #113 widened: without this, a deactivated role also grants publishing.
  describe 'POST /answers/:id/publish' do
    subject(:perform_request) do
      post "/api/v1/knowledge_bases/#{knowledge_base.id}/answers/#{internal_answer.id}/publish", as: :json

      response
    end

    include_examples 'an action the deactivated role must not authorize', authorized_status: :ok

    it 'leaves the answer unpublished' do
      internal_answer

      expect { perform_request }.not_to change { internal_answer.reload.published_at }
    end
  end

  describe 'POST /answers/:id/archive' do
    subject(:perform_request) do
      post "/api/v1/knowledge_bases/#{knowledge_base.id}/answers/#{internal_answer.id}/archive", as: :json

      response
    end

    include_examples 'an action the deactivated role must not authorize', authorized_status: :ok
  end

  describe 'POST /answers/:id/has_publishing_update' do
    subject(:perform_request) do
      post "/api/v1/knowledge_bases/#{knowledge_base.id}/answers/#{internal_answer.id}/has_publishing_update", as: :json

      response
    end

    include_examples 'an action the deactivated role must not authorize', authorized_status: :ok
  end
end
