# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::AI::Ticket::EmbedContent, :aggregate_failures do
  subject(:service_result) { described_class.execute(ticket:) }

  let(:ticket)    { create(:ticket, title: 'Printer not working') }
  let(:embedding) { [0.1] }

  before do
    setup_ai_provider('zammad_ai')
    allow(Service::AI::VectorDB::Embedding).to receive(:execute).and_return(embedding)
  end

  describe '#execute' do
    context 'with no articles' do
      it 'returns an embedding built from the ticket title' do
        expect(service_result).to eq(embedding)
        expect(Service::AI::VectorDB::Embedding).to have_received(:execute).with(
          input: include('Printer not working'),
        )
      end
    end

    context 'with plain text articles' do
      before do
        create(
          :ticket_article,
          ticket:,
          body:         "Hello, my printer stopped working.\n\n> I will send you the error next.",
          content_type: 'text/plain',
        )
        create(
          :ticket_article,
          ticket:,
          body:         "Error 404, printer not found.\n\n> Hello, my printer stopped working.\n\n> > I will send you the error next.\n> Regards",
          content_type: 'text/plain',
        )
      end

      it 'strips quotes/signatures from later articles and returns an embedding' do
        expect(service_result).to eq(embedding)
        expect(Service::AI::VectorDB::Embedding).to have_received(:execute).with(
          input: satisfy { |content|
            content.include?('Hello, my printer stopped working.') &&
            content.include?('> I will send you the error next.') &&
            content.include?('Error 404, printer not found.') &&
              content.exclude?('> Hello, my printer stopped working.') &&
              content.exclude?('> > I will send you the error next.') &&
              content.exclude?('> Regards')
          },
        )
      end
    end

    context 'with HTML articles' do
      before do
        create(
          :ticket_article,
          ticket:,
          body:         '<p>My printer broke.</p><blockquote>It shows an error.</blockquote>',
          content_type: 'text/html',
        )
        create(
          :ticket_article,
          ticket:,
          body:         '<p>Error: PC load letter</p><blockquote>My printer broke previously.</blockquote>',
          content_type: 'text/html',
        )
      end

      it 'strips quotes/signatures from later articles and returns an embedding' do
        expect(service_result).to eq(embedding)
        expect(Service::AI::VectorDB::Embedding).to have_received(:execute).with(
          input: satisfy { |content|
            content.include?('My printer broke.') &&
            content.include?('It shows an error.') &&
            content.include?('Error: PC load letter') &&
              content.exclude?('My printer broke previously.')
          },
        )
      end
    end

    context 'when content exceeds the model token limit' do
      before do
        create(:ticket_article, ticket:, body: 'Some content.', content_type: 'text/plain')
        allow(Service::AI::VectorDB::Content::Chunks::Strategy::Base)
          .to receive(:estimate_tokens).and_return(999_999)
      end

      it 'raises an error' do
        expect { service_result }.to raise_error(described_class::ContentTooLargeError)
      end

      it 'does not call the embedding service' do
        service_result
      rescue described_class::ContentTooLargeError
        nil
      ensure
        expect(Service::AI::VectorDB::Embedding).not_to have_received(:execute)
      end
    end

    context 'when content fits within the model token limit' do
      before do
        create(:ticket_article, ticket:, body: 'Some content.', content_type: 'text/plain')
        allow(Service::AI::VectorDB::Content::Chunks::Strategy::Base)
          .to receive(:estimate_tokens).and_return(100)
      end

      it 'calls the embedding service and returns the result' do
        expect(service_result).to eq(embedding)
        expect(Service::AI::VectorDB::Embedding).to have_received(:execute).once
      end
    end

    context 'when AI provider is not configured' do
      before { unset_ai_provider }

      it 'raises an error' do
        expect { service_result }.to raise_error(RuntimeError, %r{AI provider is not configured})
      end
    end
  end
end
