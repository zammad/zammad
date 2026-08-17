# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'KnowledgeBase answer publishing', authenticated_as: :current_user, type: :request do
  include_context 'basic Knowledge Base'

  let(:editor_role) { create(:role, permission_names: ['knowledge_base.editor']) }
  let(:editor)      { create(:user, roles: [editor_role]) }

  # Stock agents get knowledge_base.reader by default.
  let(:reader) { create(:agent) }

  let(:answer) { create(:knowledge_base_answer, category: category) }

  def publishing_state
    answer.reload.slice(:published_at, :internal_at, :archived_at)
  end

  shared_examples 'an editor-only publishing endpoint' do |event, start_state|
    let(:answer) { create(:knowledge_base_answer, start_state, category: category) }
    let(:url)    { "/api/v1/knowledge_bases/#{knowledge_base.id}/answers/#{answer.id}/#{event}" }

    context 'with knowledge_base.reader permissions' do
      let(:current_user) { reader }

      it 'is forbidden' do
        post url, as: :json

        expect(response).to have_http_status(:forbidden)
      end

      it 'does not change the publishing state' do
        expect { post url, as: :json }.not_to change { publishing_state }
      end
    end

    context 'with knowledge_base.editor permissions' do
      let(:current_user) { editor }

      it 'returns success' do
        post url, as: :json

        expect(response).to have_http_status(:ok)
      end

      it 'changes the publishing state' do
        expect { post url, as: :json }.to change { publishing_state }
      end
    end
  end

  # Each event is valid only from a specific state, and `error_on_all_events` swallows an invalid
  #   transition into a 200 that changes nothing — which would make the assertions above vacuous.
  def self.start_state_for(event_name)
    { internal: :draft, publish: :draft, archive: :published, unarchive: :archived }.fetch(event_name)
  end

  CanBePublished::StateMachine.aasm.events.each do |event|
    context "when firing the #{event.name} event" do
      include_examples 'an editor-only publishing endpoint', event.name, start_state_for(event.name)
    end
  end

  context 'when updating the publishing timestamps' do
    let(:url) { "/api/v1/knowledge_bases/#{knowledge_base.id}/answers/#{answer.id}/has_publishing_update" }

    context 'with knowledge_base.reader permissions' do
      let(:current_user) { reader }

      it 'is forbidden' do
        post url, params: { internal_at: '--now--' }, as: :json

        expect(response).to have_http_status(:forbidden)
      end

      it 'does not change the publishing state' do
        expect { post url, params: { internal_at: '--now--' }, as: :json }.not_to change { publishing_state }
      end
    end

    context 'with knowledge_base.editor permissions' do
      let(:current_user) { editor }

      it 'returns success' do
        post url, params: { internal_at: '--now--' }, as: :json

        expect(response).to have_http_status(:ok)
      end

      it 'changes the publishing state' do
        expect { post url, params: { internal_at: '--now--' }, as: :json }.to change { publishing_state }
      end
    end
  end
end
