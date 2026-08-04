# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# Real end-to-end coverage for the ticket -> KB-answer suggestion flow: real Elasticsearch
# (searchindex: true) and real embeddings via the Zammad AI provider (replayed from a committed
# VCR cassette). Add a scenario by dropping a JSON file into
# spec/fixtures/files/ai/related_knowledge_base_answers/ - no code changes needed. To record a
# cassette for a new/changed fixture, delete its cassette under
# test/data/vcr_cassettes/integration/ai/related_knowledge_base_answers/ and rerun with a real
# ZAMMAD_AI_TOKEN.
#
# integration_standalone keeps this out of the ES-less generic integration CI job.
RSpec.describe 'AI related knowledge base answers', :aggregate_failures, integration: true, integration_standalone: true, required_envs: %w[ZAMMAD_AI_TOKEN], searchindex: true, use_vcr: true do # rubocop:disable RSpec/DescribeClass
  let(:agent)       { create(:agent) }
  let(:kb_category) { create(:knowledge_base_category) }

  before do
    # CI's :searchindex job still runs against ES 'stable' (the current release's lowest supported
    # version), which is below vectordb's minimum - only the next release raises the floor. Skip
    # rather than fail until then.
    es_version = Gem::Version.new(SearchIndexBackend.version)
    minimum    = Gem::Version.new(AI::VectorDB::SUPPORTED_ES_VERSION_MINIMUM)
    skip "Elasticsearch #{es_version} is below the vectordb minimum (#{minimum})" if es_version < minimum

    setup_ai_provider('zammad_ai', token: ENV['ZAMMAD_AI_TOKEN'])
    Setting.set('vectordb_enabled', true)

    # No service wraps index creation (Service::AI::VectorDB::* all assume the index already
    # exists), so this is the one legitimate direct AI::VectorDB call in this spec.
    provider = AI::ProviderConnection.for_embeddings.provider_instance
    AI::VectorDB.new.migrate(dimensions: provider.class::EMBEDDING_SIZES.fetch(provider.options[:embedding_model]))
  end

  Rails.root.glob('spec/fixtures/files/ai/related_knowledge_base_answers/*.json').each do |fixture_path|
    context "with #{fixture_path.basename}" do
      let(:scenario) { JSON.parse(fixture_path.read) }

      let(:ticket) do
        ticket = create(:ticket, title: scenario['ticket']['title'])
        scenario['ticket']['articles'].each { |body| create(:ticket_article, ticket:, body:) }
        ticket
      end

      # { translation => expected_match? } - built and indexed once per example, so every
      # translation below is looked up by object identity (no key/id bookkeeping to keep in sync).
      #
      # TODO: drop no_touching once !13434 lands (fixes the answer/translation touch recursion).
      let(:knowledge_base_answers) do
        KnowledgeBase::Answer.no_touching do
          scenario['knowledge_base_answers'].to_h do |entry|
            answer = create(:knowledge_base_answer, :published, category: kb_category, translation_attributes: { title: entry['title'] })
            translation = answer.translations.first
            translation.content.update!(body: entry['body'])
            translation.vector_index_update

            [translation, entry.fetch('expected_match', false)]
          end
        end
      end

      it 'suggests every expected match, ranked above any other candidate that also surfaces' do
        raise "Fixture #{fixture_path.basename} has no answer with expected_match: true - the scenario would trivially pass" if !knowledge_base_answers.value?(true)

        SearchIndexBackend.refresh # AI embeddings share the ES cluster refreshed here, so this flushes both

        TicketAIRelatedKnowledgeBaseAnswersEmbedJob.perform_now(ticket, agent.locale, :auto, current_user: agent)

        result = Service::Ticket::AI::RelatedKnowledgeBaseAnswers.with_current_user(agent).execute(ticket:)

        expect(result[:pending]).to be false

        # Best-first (see Service::KnowledgeBase::Answer::SimilaritySearch).
        suggested_translations = result[:answers].pluck(:translation)

        expected, other = knowledge_base_answers.partition { |_translation, expected_match| expected_match }.map { |pairs| pairs.map(&:first) }

        expected.each do |translation|
          expect(suggested_translations).to include(translation), lambda {
            "Expected #{translation.title.inspect} to be suggested, but suggestions were: #{suggested_translations.map(&:title)}"
          }
        end

        # A close-but-wrong candidate is allowed to also surface (some scenarios are deliberately
        # hard to separate), but it must never outrank an expected match - only fully excluding it
        # would demand a sharper embedding model than the current one actually provides.
        worst_expected_rank = expected.filter_map { |translation| suggested_translations.index(translation) }.max

        # No expected match was suggested at all (already reported above) - nothing to rank against.
        if worst_expected_rank
          other.each do |translation|
            rank = suggested_translations.index(translation)
            next if rank.nil?

            expect(rank).to be > worst_expected_rank, lambda {
              "Expected #{translation.title.inspect} to rank below the expected match(es), but suggestions were: #{suggested_translations.map(&:title)}"
            }
          end
        end
      end
    end
  end
end
