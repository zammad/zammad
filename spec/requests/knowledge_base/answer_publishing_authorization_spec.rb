# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# The editorial lifecycle of an answer is an editor's, on both stacks: the desktop view asks
#   KnowledgeBase::AnswerPolicy#update? for it (`loads_pundit_method: :update?` on
#   Gql::Mutations::KnowledgeBase::Answer::VisibilitySchedule::Add), and these endpoints now ask the
#   same. They used to ask nothing of the kind - Controllers::KnowledgeBase::AnswersControllerPolicy
#   defined no predicate for them, so they fell through to the `default_permit!('knowledge_base.*')`
#   of a shared base policy, which `knowledge_base.reader` satisfies. A reader could publish a draft
#   onto the public help site, and archive a published answer off it. See
#   zammad/coordination-security#154.
RSpec.describe 'KnowledgeBase answer publishing authorization', type: :request do
  include_context 'basic Knowledge Base'

  let(:role) { create(:role, permission_names: [permission]) }
  let(:user) { create(:user, roles: [role]) }

  let(:base_url) { "/api/v1/knowledge_bases/#{knowledge_base.id}/answers" }

  context 'when the user is a knowledge base reader', authenticated_as: :user do
    let(:permission) { 'knowledge_base.reader' }

    it 'holds the reader permission but not the editor one', :aggregate_failures do
      expect(user.permissions?('knowledge_base.reader')).to be true
      expect(user.permissions?('knowledge_base.editor')).to be false
    end

    it 'does not resolve editor access to the answer' do
      expect(KnowledgeBase::AnswerPolicy.new(user, draft_answer).update?).to be false
    end

    # Publishing is the direction that matters: a published answer is served to anonymous visitors
    #   of the public help site, so this is unpublished content going public.
    it 'refuses to publish a draft answer', :aggregate_failures do
      expect { post "#{base_url}/#{draft_answer.id}/publish", as: :json }
        .not_to change { draft_answer.reload.published_at }

      expect(response).to have_http_status(:forbidden)
    end

    it 'refuses to make a draft answer internal', :aggregate_failures do
      expect { post "#{base_url}/#{draft_answer.id}/internal", as: :json }
        .not_to change { draft_answer.reload.internal_at }

      expect(response).to have_http_status(:forbidden)
    end

    it 'refuses to archive a published answer', :aggregate_failures do
      expect { post "#{base_url}/#{published_answer.id}/archive", as: :json }
        .not_to change { published_answer.reload.archived_at }

      expect(response).to have_http_status(:forbidden)
    end

    it 'refuses to unarchive an archived answer', :aggregate_failures do
      expect { post "#{base_url}/#{archived_answer.id}/unarchive", as: :json }
        .not_to change { archived_answer.reload.archived_at }

      expect(response).to have_http_status(:forbidden)
    end

    # The same lifecycle written through the timestamps directly rather than through a transition,
    #   so gating only the four events would have left the whole thing reachable.
    it 'refuses to write the publishing timestamps directly', :aggregate_failures do
      expect { post "#{base_url}/#{draft_answer.id}/has_publishing_update", params: { published_at: '--now--' }, as: :json }
        .not_to change { draft_answer.reload.published_at }

      expect(response).to have_http_status(:forbidden)
    end

    # Unchanged by this: reading the answer, and the recently published list, stay a reader's.
    it 'still reads an answer it may see' do
      get "#{base_url}/#{published_answer.id}", as: :json

      expect(response).to have_http_status(:ok)
    end

    it 'still reads the recently published answers' do
      get '/api/v1/knowledge_bases/recent_answers', as: :json

      expect(response).to have_http_status(:ok)
    end
  end

  context 'when the user is a knowledge base editor', authenticated_as: :user do
    let(:permission) { 'knowledge_base.editor' }

    it 'publishes a draft answer', :aggregate_failures do
      expect { post "#{base_url}/#{draft_answer.id}/publish", as: :json }
        .to change { draft_answer.reload.published_at }.from(nil)

      expect(response).to have_http_status(:ok)
    end

    it 'archives a published answer', :aggregate_failures do
      expect { post "#{base_url}/#{published_answer.id}/archive", as: :json }
        .to change { published_answer.reload.archived_at }.from(nil)

      expect(response).to have_http_status(:ok)
    end

    it 'writes the publishing timestamps directly', :aggregate_failures do
      expect { post "#{base_url}/#{draft_answer.id}/has_publishing_update", params: { published_at: '--now--' }, as: :json }
        .to change { draft_answer.reload.published_at }.from(nil)

      expect(response).to have_http_status(:ok)
    end
  end
end
