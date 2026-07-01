# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe TicketAIRelatedKnowledgeBaseAnswersEmbedJob, :aggregate_failures, type: :job do
  let(:ticket)           { create(:ticket) }
  let(:locale)           { 'en-us' }
  let(:current_user)     { create(:agent) }
  let(:embedding)        { [0.1, 0.2, 0.3] }
  let(:embedding_source) { :auto }

  def perform
    described_class.perform_now(ticket, locale, embedding_source, current_user:)
  end

  before do
    allow(Service::Ticket::AI::RelatedKnowledgeBaseAnswers::EmbeddingCache).to receive(:store)
    allow(Service::Ticket::AI::RelatedKnowledgeBaseAnswers).to receive(:broadcast_ping)
    allow(Service::Ticket::AI::RelatedKnowledgeBaseAnswers).to receive(:broadcast_error)
    allow(Service::AI::Ticket::EmbedContent).to receive(:execute).and_return(embedding)
    allow(Service::AI::Ticket::EmbedSummary).to receive(:execute).and_return(embedding)
  end

  context 'with the :auto source' do
    context 'when the ticket content can be embedded' do
      it 'caches the content embedding and pings, without touching the summary' do
        perform

        expect(Service::Ticket::AI::RelatedKnowledgeBaseAnswers::EmbeddingCache)
          .to have_received(:store).with(ticket:, embedding_source: :auto, locale:, embedding:)
        expect(Service::Ticket::AI::RelatedKnowledgeBaseAnswers).to have_received(:broadcast_ping).with(ticket)
        expect(Service::AI::Ticket::EmbedSummary).not_to have_received(:execute)
      end
    end

    context 'when the ticket content is too large to embed' do
      before do
        allow(Service::AI::Ticket::EmbedContent)
          .to receive(:execute)
          .and_raise(Service::AI::Ticket::EmbedContent::ContentTooLargeError, 'too large')
      end

      it 'falls back to the summary embedding, caches it, and pings' do
        perform

        expect(Service::AI::Ticket::EmbedSummary).to have_received(:execute).with(ticket:, locale:, current_user:)
        expect(Service::Ticket::AI::RelatedKnowledgeBaseAnswers::EmbeddingCache)
          .to have_received(:store).with(ticket:, embedding_source: :auto, locale:, embedding:)
      end

      context 'when no summary can be produced' do
        before { allow(Service::AI::Ticket::EmbedSummary).to receive(:execute).and_return(nil) }

        it 'caches nothing and reports the error to the clients' do
          perform

          expect(Service::Ticket::AI::RelatedKnowledgeBaseAnswers::EmbeddingCache).not_to have_received(:store)
          expect(Service::Ticket::AI::RelatedKnowledgeBaseAnswers)
            .to have_received(:broadcast_error).with(ticket, 'The suggestions could not be generated.')
        end
      end
    end
  end

  context 'with the :summary source (forced)' do
    let(:embedding_source) { :summary }

    it 'embeds the summary and never the content' do
      perform

      expect(Service::AI::Ticket::EmbedSummary).to have_received(:execute).with(ticket:, locale:, current_user:)
      expect(Service::AI::Ticket::EmbedContent).not_to have_received(:execute)
      expect(Service::Ticket::AI::RelatedKnowledgeBaseAnswers::EmbeddingCache)
        .to have_received(:store).with(ticket:, embedding_source: :summary, locale:, embedding:)
    end
  end

  context 'when embedding raises an error' do
    before do
      allow(Service::AI::Ticket::EmbedContent).to receive(:execute).and_raise(StandardError, 'boom')
    end

    it 'caches nothing and reports the error to the clients' do
      perform

      expect(Service::Ticket::AI::RelatedKnowledgeBaseAnswers::EmbeddingCache).not_to have_received(:store)
      expect(Service::Ticket::AI::RelatedKnowledgeBaseAnswers).not_to have_received(:broadcast_ping)
      expect(Service::Ticket::AI::RelatedKnowledgeBaseAnswers).to have_received(:broadcast_error).with(ticket, 'boom')
    end
  end
end
