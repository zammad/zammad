# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::AI::Ticket::EmbedSummary, :aggregate_failures do
  subject(:service_result) { described_class.with_current_user(agent).execute(ticket:) }

  let(:agent)     { create(:agent) }
  let(:ticket)    { create(:ticket, title: 'Printer not working') }
  let(:embedding) { [0.1] }

  let(:summary_content) do
    {
      'customer_request'     => 'Printer keeps jamming.',
      'conversation_summary' => ['Technician was contacted.', 'Issue was identified.'],
      'language'             => 'en-us',
    }
  end

  let(:summarize_result) do
    Service::AI::Feature::Result[
      content:          summary_content,
      stored_result:    instance_double(AI::StoredResult),
      fresh:            false,
      ai_analytics_run: nil,
    ]
  end

  before do
    setup_ai_provider('zammad_ai')
    allow(Service::AI::VectorDB::Embedding).to receive(:execute).and_return(embedding)
  end

  describe '#execute' do
    context 'when no summary can be produced' do
      before do
        allow(Service::Ticket::AIAssistance::Summarize).to receive(:execute).and_return(nil)
      end

      it 'returns nil without embedding' do
        expect(service_result).to be_nil
        expect(Service::AI::VectorDB::Embedding).not_to have_received(:execute)
      end
    end

    context 'when a summary is available' do
      before do
        allow(Service::Ticket::AIAssistance::Summarize).to receive(:execute).and_return(summarize_result)
      end

      it 'fetches or generates the summary (no stored_only strategy)' do
        service_result
        expect(Service::Ticket::AIAssistance::Summarize)
          .to have_received(:execute)
          .with(satisfy { |args| args[:ticket] == ticket && args[:locale] == agent.locale && !args.key?(:persistence_strategy) })
      end

      it 'returns the embedding vector' do
        expect(service_result).to eq(embedding)
      end

      it 'embeds ticket title, customer_request, and conversation_summary' do
        service_result
        expect(Service::AI::VectorDB::Embedding).to have_received(:execute).with(
          input: satisfy { |content|
            content.include?('Printer not working') &&
              content.include?('Printer keeps jamming.') &&
              content.include?('Technician was contacted.') &&
              content.include?('Issue was identified.')
          },
        )
      end

      it 'excludes non-summary keys from the embedded content' do
        service_result
        expect(Service::AI::VectorDB::Embedding).to have_received(:execute).with(
          input: satisfy { |content| content.exclude?('en-us') },
        )
      end

      context 'when content exceeds the model token limit' do
        before do
          allow(Service::AI::VectorDB::Content::Chunks::Strategy::Base)
            .to receive(:estimate_tokens).and_return(999_999)
        end

        it 'raises ContentTooLargeError without embedding' do
          expect { service_result }.to raise_error(described_class::ContentTooLargeError)
          expect(Service::AI::VectorDB::Embedding).not_to have_received(:execute)
        end
      end

      context 'when an explicit locale is given' do
        it 'fetches the summary for that locale' do
          described_class.with_current_user(agent).execute(ticket:, locale: 'de-de')

          expect(Service::Ticket::AIAssistance::Summarize)
            .to have_received(:execute).with(hash_including(locale: 'de-de'))
        end
      end
    end

    context 'when AI provider is not configured' do
      before do
        allow(Service::Ticket::AIAssistance::Summarize).to receive(:execute).and_return(summarize_result)
        unset_ai_provider
      end

      it 'raises an error' do
        expect { service_result }.to raise_error(RuntimeError, %r{AI provider is not configured})
      end
    end
  end
end
