# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::Ticket::AIAssistance::GenerateKnowledgeBaseAnswerContent do
  subject(:service) { described_class.new(ticket:, current_user:, locale: 'en-us', category_options:) }

  let(:ticket)           { create(:ticket) }
  let(:current_user)     { create(:admin) }
  let(:category_options) { [{ value: 1, label: 'Category' }] }

  before do
    setup_ai_provider('open_ai')
  end

  describe '#execute' do
    context 'when ticket has no articles' do
      it 'returns nil' do
        expect(service.execute).to be_nil
      end
    end

    context 'with valid ticket and articles' do
      let(:ai_result) { AI::Service::Result.new(content: { 'title' => 'Generated title' }) }

      before do
        create(:ticket_article, ticket:)
        allow_any_instance_of(AI::Service::KnowledgeBaseAnswerFromTicket).to receive(:execute).and_return(ai_result)
      end

      it 'returns AI generated content' do
        expect(service.execute).to eq(ai_result)
      end
    end

    context 'when ai_provider is not configured' do
      before do
        unset_ai_provider
      end

      it 'raises an error' do
        expect { service.execute }.to raise_error(Service::CheckFeatureEnabled::FeatureDisabledError, 'AI provider is not configured.')
      end
    end
  end
end
