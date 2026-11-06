# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# The coverage values of the agent harness's knowledge base search for Zammad AI's embedding model, held against a real
# Elasticsearch and real embeddings (replayed from a committed VCR cassette) on made-up answers: every question that has
# an answer lists it — in English and in German against English answers, which score a few points lower — and no
# question without one reads covered. A recording with another embedding model behind Zammad AI shows here whether the
# values still hold. To record the cassette again, delete it under
# test/data/vcr_cassettes/integration/ai/knowledge_base_search_coverage/ and rerun with a real ZAMMAD_AI_TOKEN.
#
# integration_standalone keeps this out of the ES-less generic integration CI job.
RSpec.describe 'AI knowledge base search coverage', :aggregate_failures, integration: true, integration_standalone: true, required_envs: %w[ZAMMAD_AI_TOKEN], searchindex: true, use_vcr: true do # rubocop:disable RSpec/DescribeClass
  let(:scenario) { JSON.parse(Rails.root.join('spec/fixtures/files/ai/harness/knowledge_base_coverage.json').read) }
  let(:category) { create(:knowledge_base_category) }
  let(:agent)    { create(:agent) }

  before do
    setup_ai_provider('zammad_ai', token: ENV['ZAMMAD_AI_TOKEN'])
    Setting.set('vectordb_enabled', true)

    # No service wraps index creation, so this is the one direct AI::VectorDB call here; the index holds what the
    #   current configuration embeds, as a finished rebuild records it.
    provider = AI::ProviderConnection.for_embeddings.provider_instance
    AI::VectorDB.new.migrate(dimensions: provider.class.known_embedding_default(:EMBEDDING_SIZES, provider.embedding_model))
    Service::AI::VectorDB::Embedding::Configuration.record_indexed(Service::AI::VectorDB::Embedding::Configuration.current)

    KnowledgeBase::Answer.no_touching do
      scenario['answers'].each do |entry|
        translation = create(:knowledge_base_answer, :published, category:, translation_attributes: { title: entry['title'] }).translations.first
        translation.content.update!(body: entry['body'])
        translation.vector_index_update
      end
    end

    SearchIndexBackend.refresh
  end

  def search(query)
    tool_call = AI::Provider::Completion::ToolCall.new(id: 'call_1', name: 'search_knowledge_base', arguments: { query: })

    Service::AI::Tool::Runtime::PerformCall.execute(surface: :harness, user: agent, tool_call:, audience: AI::Harness::Audience::HUMAN_AGENTS).content
  end

  it 'lists the answer of every question that has one, and calls no question without one covered' do
    scenario['questions_with_an_answer'].each do |question|
      result = search(question['query'])

      expect(result[:mode]).to eq('semantic')
      expect(result[:answers].pluck(:title)).to include(question['answer']), -> { "#{question['query']}: #{result[:answers].pluck(:title)}" }
    end

    scenario['questions_without_an_answer'].each do |query|
      result = search(query)

      expect(result[:coverage]).not_to eq('covered'), -> { "#{query}: #{result[:answers].pluck(:title)}" }
    end
  end
end
