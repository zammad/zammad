# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::KnowledgeBase::Answer::SimilaritySearch, :aggregate_failures do
  subject(:service) { described_class.with_current_user(user).execute(embedding:, limit:, locale:) }

  let(:embedding) { [0.1, 0.2, 0.3] }
  let(:limit)     { 3 }
  let(:locale)    { nil }

  def hit(translation, score)
    {
      '_score'  => score,
      '_source' => {
        'object_name' => 'KnowledgeBase::Answer::Translation',
        'object_id'   => translation.id.to_s,
        'content'     => translation.title,
      },
    }
  end

  def stub_search(hits)
    allow(Service::AI::VectorDB::SimilaritySearch)
      .to receive(:execute)
      .and_return({ 'hits' => { 'hits' => hits } })
  end

  # Capture the filter passed into the vector search (permissions/locale are applied in the query).
  def captured_search_filter
    filter = nil
    allow(Service::AI::VectorDB::SimilaritySearch).to receive(:execute) do |**kwargs|
      filter = kwargs[:filter]
      { 'hits' => { 'hits' => [] } }
    end
    service
    filter
  end

  context 'when the user may see all knowledge base answers' do
    let(:role) { create(:role, permission_names: %w[ticket.agent knowledge_base.editor]) }
    let(:user) { create(:agent, roles: [role]) }

    let(:answer_1) { create(:knowledge_base_answer, :published) }
    let(:answer_2) { create(:knowledge_base_answer, :published) }
    let(:answer_3) { create(:knowledge_base_answer, :internal) }
    let(:answer_4) { create(:knowledge_base_answer, :published) }

    it 'returns the matching translations with score, ordered by relevance, limited to the given limit' do
      stub_search([
                    hit(answer_4.translations.first, 0.82),
                    hit(answer_1.translations.first, 0.98),
                    hit(answer_2.translations.first, 0.92),
                    hit(answer_3.translations.first, 0.86),
                  ])

      expect(service).to eq([
                              { translation: answer_1.translations.first, score: 0.98 },
                              { translation: answer_2.translations.first, score: 0.92 },
                              { translation: answer_3.translations.first, score: 0.86 },
                            ])
    end

    it 'respects a smaller limit' do
      stub_search([
                    hit(answer_1.translations.first, 0.95),
                    hit(answer_2.translations.first, 0.85),
                  ])

      expect(described_class.with_current_user(user).execute(embedding:, limit: 1).pluck(:translation))
        .to eq([answer_1.translations.first])
    end

    it 'deduplicates an answer that matches with multiple chunks, keeping the best score' do
      translation = answer_1.translations.first

      stub_search([
                    hit(translation, 0.85),
                    hit(translation, 0.95),
                  ])

      expect(service).to eq([{ translation:, score: 0.95 }])
    end

    it 'ignores hits below the minimum score' do
      stub_search([
                    hit(answer_1.translations.first, described_class::MINIMUM_SCORE),
                    hit(answer_2.translations.first, described_class::MINIMUM_SCORE - 0.1),
                  ])

      expect(service.pluck(:translation)).to eq([answer_1.translations.first])
    end
  end

  context 'when applying permissions' do
    let(:user)             { create(:agent) }
    let(:published_answer) { create(:knowledge_base_answer, :published) }
    let(:draft_answer)     { create(:knowledge_base_answer, :draft) }

    before do
      published_answer
      draft_answer
    end

    it 'searches only within the answers the user is allowed to see' do
      filter = captured_search_filter

      expect(filter[:object_name]).to eq('KnowledgeBase::Answer::Translation')
      expect(filter[:'metadata.answer_id']).to include(published_answer.id)
      expect(filter[:'metadata.answer_id']).not_to include(draft_answer.id)
    end

    it 'does not search at all when the user may see no answers' do
      allow(KnowledgeBase::Answer).to receive(:visible_to_user).and_return(KnowledgeBase::Answer.none)
      allow(Service::AI::VectorDB::SimilaritySearch).to receive(:execute)

      expect(service).to eq([])
      expect(Service::AI::VectorDB::SimilaritySearch).not_to have_received(:execute)
    end
  end

  context 'when restricting to a locale' do
    let(:role)      { create(:role, permission_names: %w[knowledge_base.editor]) }
    let(:user)      { create(:agent, roles: [role]) }
    let(:locale)    { 'en-us' }
    let(:answer_en) { create(:knowledge_base_answer, :published) }

    before { answer_en }

    it 'restricts the search to the given locale' do
      expect(captured_search_filter).to include('metadata.locale': 'en-us')
    end
  end

  context 'when excluding specific answer ids' do
    let(:role)     { create(:role, permission_names: %w[knowledge_base.editor]) }
    let(:user)     { create(:agent, roles: [role]) }
    let(:excluded) { create(:knowledge_base_answer, :published) }
    let(:kept)     { create(:knowledge_base_answer, :published) }

    before do
      excluded
      kept
    end

    it 'drops them from the searched ids' do
      filter = nil
      allow(Service::AI::VectorDB::SimilaritySearch).to receive(:execute) do |**kwargs|
        filter = kwargs[:filter]
        { 'hits' => { 'hits' => [] } }
      end

      described_class.with_current_user(user).execute(embedding:, excluded_answer_ids: [excluded.id])

      expect(filter[:'metadata.answer_id']).to include(kept.id)
      expect(filter[:'metadata.answer_id']).not_to include(excluded.id)
    end

    it 'does not search when excluding leaves no visible answers' do
      allow(Service::AI::VectorDB::SimilaritySearch).to receive(:execute)

      result = described_class
        .with_current_user(user)
        .execute(embedding:, excluded_answer_ids: KnowledgeBase::Answer.pluck(:id))

      expect(result).to eq([])
      expect(Service::AI::VectorDB::SimilaritySearch).not_to have_received(:execute)
    end
  end

  context 'when the embedding is blank' do
    let(:user)      { create(:agent) }
    let(:embedding) { nil }

    it 'returns an empty array without performing a search' do
      allow(Service::AI::VectorDB::SimilaritySearch).to receive(:execute)

      expect(service).to eq([])
      expect(Service::AI::VectorDB::SimilaritySearch).not_to have_received(:execute)
    end
  end

  context 'when no answers match' do
    let(:role) { create(:role, permission_names: %w[knowledge_base.editor]) }
    let(:user) { create(:agent, roles: [role]) }

    before { create(:knowledge_base_answer, :published) }

    it 'returns an empty array' do
      stub_search([])

      expect(service).to eq([])
    end
  end
end
