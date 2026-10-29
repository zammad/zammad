# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# The summary behaviour is covered in spec/services/service/ticket/ai_assistance/stored_summary_spec.rb,
#   the excerpt behaviour in spec/models/ticket/article_spec.rb.
RSpec.describe 'Ticket Popover API endpoint', authenticated_as: :user, performs_jobs: true, type: :request do
  let(:user)    { create(:agent, groups: [ticket.group]) }
  let(:ticket)  { create(:ticket) }
  let(:summary) { nil }

  before do
    allow(Service::Ticket::AIAssistance::StoredSummary).to receive(:execute)
      .with(hash_including(ticket:))
      .and_return(summary)
  end

  def make_request
    get "/api/v1/tickets/#{ticket.id}/popover", as: :json
  end

  context 'when the user has no agent access to the ticket' do
    let(:user) { create(:agent) }

    it 'responds with forbidden' do
      make_request

      expect(response).to have_http_status(:forbidden)
    end
  end

  context 'when the user is the customer of the ticket' do
    let(:user)   { create(:customer) }
    let(:ticket) { create(:ticket, customer: user) }

    it 'responds with forbidden' do
      make_request

      expect(response).to have_http_status(:forbidden)
    end
  end

  context 'with a stored summary' do
    let(:summary) do
      {
        'customer_request'     => 'Customer wants a corrected invoice.',
        'conversation_summary' => 'A conversation.',
        'customer_emotion'     => 'neutral',
        'customer_mood'        => 'sad',
      }
    end

    it 'returns the intent and the sentiment only' do
      make_request

      expect(json_response['summary']).to eq(
        'customer_request' => 'Customer wants a corrected invoice.',
        'customer_emotion' => 'neutral',
        'customer_mood'    => 'sad',
      )
    end
  end

  context 'with a stored summary that carries none of the popover parts' do
    let(:summary) { { 'conversation_summary' => 'A conversation.' } }

    it 'returns no summary' do
      make_request

      expect(json_response['summary']).to be_nil
    end
  end

  context 'without a stored summary' do
    before { create(:ticket_article, :inbound_web, ticket:) }

    it 'returns no summary and enqueues no generation', :aggregate_failures do
      make_request

      expect(json_response['summary']).to be_nil
      expect(json_response['first_article']).to be_present
      expect(TicketAIAssistanceSummarizeJob).not_to have_been_enqueued
    end

    it 'returns no analytics and no unread information' do
      make_request

      expect(json_response.keys).to match_array(%w[summary first_article last_article checklist assets])
    end
  end

  context 'with several articles' do
    let(:first_article) { create(:ticket_article, :inbound_web, ticket:, body: 'A question.') }
    let(:last_article)  { create(:ticket_article, :internal_note, ticket:, body: 'A remark.') }

    before do
      create(:ticket_article, :system_delivery_message, ticket:)
      first_article
      last_article
      create(:ticket_article, :system_delivery_message, ticket:)
    end

    it 'returns the first and the last article, skipping system notifications' do
      make_request

      expect(json_response).to include(
        'first_article' => include(
          'id'           => first_article.id,
          'body_excerpt' => 'A question.',
          'author'       => { 'id' => first_article.author_id },
          'sender'       => first_article.sender.name,
          'internal'     => false,
        ),
        'last_article'  => include('id' => last_article.id, 'body_excerpt' => 'A remark.', 'internal' => true),
      )
    end

    it 'returns the authors as assets' do
      make_request

      expect(json_response['assets']['User'].keys).to include(
        first_article.author_id.to_s, last_article.author_id.to_s
      )
    end
  end

  context 'with a single article' do
    let(:article) { create(:ticket_article, :inbound_web, ticket:) }

    before { article }

    it 'returns it as the first and as the last article' do
      make_request

      expect(json_response).to include(
        'first_article' => include('id' => article.id),
        'last_article'  => include('id' => article.id),
      )
    end
  end

  context 'with system notifications only' do
    before { create(:ticket_article, :system_delivery_message, ticket:) }

    it 'returns no articles' do
      make_request

      expect(json_response).to include('first_article' => nil, 'last_article' => nil)
    end
  end

  context 'with a checklist', current_user_id: 1 do
    before do
      Setting.set('checklist', checklist_setting)

      create(:checklist, ticket:, item_count: 3).items.first.update!(checked: true)
    end

    let(:checklist_setting) { true }

    it 'returns the complete and the total count' do
      make_request

      expect(json_response['checklist']).to eq('complete' => 1, 'total' => 3)
    end

    context 'when the checklist feature is disabled' do
      let(:checklist_setting) { false }

      it 'returns no checklist' do
        make_request

        expect(json_response['checklist']).to be_nil
      end
    end
  end

  context 'without a checklist' do
    it 'returns no checklist' do
      make_request

      expect(json_response['checklist']).to be_nil
    end
  end
end
