# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::Ticket::AI::RelatedKnowledgeBaseAnswers, :aggregate_failures do
  let(:user)          { create(:agent) }
  let(:ticket)        { create(:ticket) }
  let(:embedding)     { [0.1, 0.2, 0.3] }
  let(:answer)        { create(:knowledge_base_answer, :published) }
  let(:translation)   { answer.translations.first }
  let(:search_result) { [{ translation:, score: 0.9 }] }

  describe '#execute', performs_jobs: true do
    subject(:service) { described_class.with_current_user(user).execute(ticket:) }

    before do
      allow(Service::KnowledgeBase::Answer::SimilaritySearch).to receive(:execute).and_return(search_result)
    end

    context 'when the ticket embedding is cached' do
      before { allow(described_class::EmbeddingCache).to receive(:lookup).and_return(embedding) }

      it 'searches synchronously and returns the answers' do
        expect(service).to eq(answers: [{ translation:, score: 0.9 }], pending: false)
        expect(Service::KnowledgeBase::Answer::SimilaritySearch)
          .to have_received(:execute).with(embedding:, limit: described_class::RESULT_LIMIT, excluded_answer_ids: [], current_user: user)
      end

      it 'does not enqueue the embed job' do
        service

        expect(TicketAIRelatedKnowledgeBaseAnswersEmbedJob).not_to have_been_enqueued
      end

      context 'when a knowledge base answer is already linked to the ticket' do
        before do
          Link.add(
            link_type:                'normal',
            link_object_source:       'KnowledgeBase::Answer::Translation',
            link_object_source_value: translation.id,
            link_object_target:       'Ticket',
            link_object_target_value: ticket.id,
          )
        end

        it 'excludes the linked answer from the search' do
          service

          expect(Service::KnowledgeBase::Answer::SimilaritySearch)
            .to have_received(:execute).with(embedding:, limit: described_class::RESULT_LIMIT, excluded_answer_ids: [answer.id], current_user: user)
        end
      end
    end

    context 'when the ticket embedding is not cached yet' do
      before { allow(described_class::EmbeddingCache).to receive(:lookup).and_return(nil) }

      it 'reports pending and enqueues the embed job with the :auto source, without searching' do
        expect(service).to eq(answers: nil, pending: true)
        expect(TicketAIRelatedKnowledgeBaseAnswersEmbedJob)
          .to have_been_enqueued.with(ticket, user.locale, :auto, current_user: user)
        expect(Service::KnowledgeBase::Answer::SimilaritySearch).not_to have_received(:execute)
      end
    end

    context 'when an embedding source is forced (testing hook)' do
      subject(:service) { described_class.with_current_user(user).execute(ticket:, embedding_source: 'summary') }

      before { allow(described_class::EmbeddingCache).to receive(:lookup).and_return(nil) }

      it 'enqueues the embed job with that source' do
        service

        expect(TicketAIRelatedKnowledgeBaseAnswersEmbedJob)
          .to have_been_enqueued.with(ticket, user.locale, :summary, current_user: user)
      end
    end
  end
end
