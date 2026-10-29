# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::Ticket::AIAssistance::StoredSummary do
  let(:user)    { create(:agent, groups: [ticket.group]) }
  let(:ticket)  { create(:ticket_article).ticket }
  let(:content) { { 'customer_request' => 'Customer wants a corrected invoice.' } }

  before do
    setup_ai_provider
    Setting.set('ai_assistance_ticket_summary', true)
  end

  def store_summary(for_ticket: ticket, locale: Locale.find_by(locale: user.locale))

    AI::StoredResult.create!(
      content:,
      version: Service::AI::Feature::TicketSummarize.lookup_version({ articles: for_ticket.articles.without_system_notifications }, locale),
      **Service::AI::Feature::TicketSummarize.lookup_attributes({ ticket: for_ticket }, locale),
    )
  end

  def execute_service
    described_class.with_current_user(user).execute(ticket:)
  end

  it 'requires a current user' do
    expect { described_class.execute(ticket:) }.to raise_error(%r{Current user is required})
  end

  context 'with a current user' do
    it 'returns the stored summary' do
      store_summary

      expect(execute_service).to eq(content)
    end

    it 'returns nothing without a stored summary' do
      expect(execute_service).to be_nil
    end

    it 'does not ask the AI provider without a stored summary' do
      expect { execute_service }.not_to change(AI::Analytics::Run, :count)
    end

    it 'returns nothing when only a summary in another locale is stored' do
      store_summary(locale: Locale.find_by(locale: 'de-de'))

      expect(execute_service).to be_nil
    end

    it 'returns nothing once a new article made the stored summary stale' do
      store_summary
      travel 1.minute
      create(:ticket_article, ticket:)

      expect(execute_service).to be_nil
    end

    it 'returns nothing when the summary is disabled' do
      store_summary
      Setting.set('ai_assistance_ticket_summary', false)

      expect(execute_service).to be_nil
    end

    it 'returns nothing when no AI provider is configured' do
      store_summary
      Setting.set('ai_provider', false)

      expect(execute_service).to be_nil
    end

    context 'when the user has no agent access to the ticket' do
      let(:user) { create(:agent) }

      it 'returns nothing' do
        store_summary

        expect(execute_service).to be_nil
      end
    end
  end
end
