# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::Ticket::AIAssistance::GenerateKnowledgeBaseAnswerContent do
  subject(:service_result) do
    described_class
      .with_current_user(current_user)
      .execute(ticket:, locale: 'en-us', category_options:)
  end

  let(:ticket)           { create(:ticket) }
  let(:current_user)     { create(:admin) }
  let(:category_options) { [{ value: 1, label: 'Category' }] }

  before do
    setup_ai_provider('open_ai')
  end

  describe '#execute' do
    context 'when ticket has no articles' do
      it 'returns nil' do
        expect(service_result).to be_nil
      end
    end

    context 'with valid ticket and articles' do
      let(:ai_result) { Service::AI::Feature::Result[content: { 'title' => 'Generated title' }] }

      before do
        create(:ticket_article, ticket:)
        allow_any_instance_of(Service::AI::Feature::KnowledgeBaseAnswerFromTicket).to receive(:execute).and_return(ai_result)
      end

      it 'returns AI generated content' do
        expect(service_result).to eq(ai_result)
      end
    end

    context 'when ai_provider is not configured' do
      before do
        unset_ai_provider
      end

      it 'raises an error' do
        expect { service_result }.to raise_error(Service::CheckFeatureEnabled::FeatureDisabledError, 'AI provider is not configured.')
      end
    end
  end
end
