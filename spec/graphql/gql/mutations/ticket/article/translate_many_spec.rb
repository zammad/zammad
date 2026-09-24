# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# What is translated, and who may, is covered by
# spec/services/service/content_translation/ticket_article/translate_many_spec.rb.
RSpec.describe Gql::Mutations::Ticket::Article::TranslateMany, :aggregate_failures, performs_jobs: true, type: :graphql do
  let(:ticket)        { create(:ticket) }
  let!(:articles)     { create_list(:ticket_article, 2, ticket:, body: '<p>Hello world.</p>', content_type: 'text/html') }
  let(:agent)         { create(:agent, groups: [ticket.group]) }
  let(:target_locale) { 'de-de' }
  let(:locale)        { Locale.find_by(locale: target_locale) }

  let(:query) do
    <<~MUTATION
      mutation ticketArticleTranslateMany(
        $ticketId: ID!, $targetLocale: String!, $pageSize: Int, $firstArticlesCount: Int,
        $loadFirstArticles: Boolean, $beforeCursor: String, $afterCursor: String,
        $generateMissing: Boolean = false, $includeContent: Boolean! = true
      ) {
        ticketArticleTranslateMany(
          ticketId: $ticketId, targetLocale: $targetLocale, pageSize: $pageSize,
          firstArticlesCount: $firstArticlesCount, loadFirstArticles: $loadFirstArticles,
          beforeCursor: $beforeCursor, afterCursor: $afterCursor, generateMissing: $generateMissing
        ) {
          pendingArticleIds
          results {
            article {
              id
              translationAvailable(targetLocale: $targetLocale)
              translation(targetLocale: $targetLocale) @include(if: $includeContent) { content backend translated }
            }
            translated
            analytics @include(if: $includeContent) {
              run {
                id
              }
              usage {
                userHasProvidedFeedback
              }
            }
          }
        }
      }
    MUTATION
  end

  let(:variables) do
    {
      ticketId:        gql.id(ticket),
      pageSize:        2,
      targetLocale:    target_locale,
      generateMissing: true,
      includeContent:  true,
    }
  end

  def store_translation(article, translation, analytics_run: nil)
    Service::ContentTranslation::StoredTranslation.save(
      object:        article,
      locale:,
      content:       article.body,
      html:          true,
      backend:       'ai',
      translation:,
      analytics_run:,
    )
  end

  context 'when logged in as an agent', authenticated_as: :agent do
    before do
      setup_ai_provider
      setup_content_translation
      Setting.set('content_translation_ticket_article_auto', true)
    end

    context 'with stored, skipped and pending translations' do
      let(:variables) { super().merge(pageSize: 3) }
      let!(:skipped_article) { create(:ticket_article, ticket:, detected_language: 'de', content_type: 'text/html') }

      before do
        store_translation(articles.first, '<p>Hallo Welt.</p>')
        store_translation(skipped_article, '<p>Manuell</p>')
      end

      it 'returns completed outcomes and leaves pending articles to the subscription' do
        allow(Service::ContentTranslation::TicketArticle).to receive(:stored_translations).and_call_original
        gql.execute(query, variables:)

        expect(gql.result.data[:pendingArticleIds]).to eq([gql.id(articles.last)])
        expect(Service::ContentTranslation::TicketArticle).to have_received(:stored_translations).with([skipped_article], target_locale).once
        expect(gql.result.data[:results]).to contain_exactly(
          {
            'article'    => { 'id' => gql.id(articles.first), 'translationAvailable' => true, 'translation' => { 'content' => '<p>Hallo Welt.</p>', 'backend' => 'ai', 'translated' => true } },
            'translated' => true,
            'analytics'  => { 'run' => nil, 'usage' => nil },
          },
          {
            'article'    => { 'id' => gql.id(skipped_article), 'translationAvailable' => true, 'translation' => { 'content' => '<p>Manuell</p>', 'backend' => 'ai', 'translated' => true } },
            'translated' => false,
            'analytics'  => { 'run' => nil, 'usage' => nil },
          },
          {
            'article'    => { 'id' => gql.id(articles.last), 'translationAvailable' => false, 'translation' => nil },
            'translated' => nil,
            'analytics'  => nil,
          }
        )
      end
    end

    context 'with a stored translation that came from an analytics run' do
      let(:run) { create(:ai_analytics_run, related_object: articles.first) }

      before { store_translation(articles.first, '<p>Hallo Welt.</p>', analytics_run: run) }

      def result_for(article)
        gql.result.data[:results].find { |result| result.dig('article', 'id') == gql.id(article) }
      end

      it 'returns the run for the feedback widget' do
        gql.execute(query, variables:)

        expect(result_for(articles.first)['analytics']).to eq(
          'run'   => { 'id' => gql.id(run) },
          'usage' => nil,
        )
      end

      it 'returns the feedback the current user gave' do
        create(:ai_analytics_usage, ai_analytics_run: run, user: agent, rating: 1)

        gql.execute(query, variables:)

        expect(result_for(articles.first)['analytics'])
          .to include('usage' => { 'userHasProvidedFeedback' => true })
      end
    end

    it 'defaults to a metadata-only lookup without requiring automatic translation permission' do
      Setting.set('content_translation_ticket_article_auto', false)
      store_translation(articles.first, '<p>Hallo Welt.</p>')
      allow(Service::ContentTranslation::TicketArticle).to receive(:execute).and_call_original
      queries = []
      subscriber = ActiveSupport::Notifications.subscribe('sql.active_record') do |*, payload|
        queries << payload[:sql] if payload[:sql].include?('FROM "ai_stored_results"')
      end

      gql.execute(query, variables: variables.except(:generateMissing).merge(includeContent: false))

      expect(gql.result.data[:pendingArticleIds]).to be_empty
      expect(gql.result.data[:results]).to contain_exactly(
        { 'article' => { 'id' => gql.id(articles.first), 'translationAvailable' => true }, 'translated' => nil },
        { 'article' => { 'id' => gql.id(articles.last), 'translationAvailable' => false }, 'translated' => nil }
      )
      expect(queries.size).to eq(1)
      expect(queries.first).not_to include('"ai_stored_results"."content"')
      expect(Service::ContentTranslation::TicketArticle).not_to have_received(:execute)
      expect(ContentTranslationJob).not_to have_been_enqueued
    ensure
      ActiveSupport::Notifications.unsubscribe(subscriber)
    end

    context 'with paginated articles' do
      let!(:articles) { create_list(:ticket_article, 8, ticket:) }

      let(:list_query) do
        <<~QUERY
          query ticketArticles(
            $ticketId: ID!, $pageSize: Int, $firstArticlesCount: Int = 1,
            $loadFirstArticles: Boolean = true, $beforeCursor: String, $afterCursor: String
          ) {
            firstArticles: ticketArticles(ticketId: $ticketId, first: $firstArticlesCount) @include(if: $loadFirstArticles) {
              edges { node { id } }
            }
            articles: ticketArticles(ticketId: $ticketId, last: $pageSize, before: $beforeCursor, after: $afterCursor) {
              edges { node { id } cursor }
            }
          }
        QUERY
      end

      def list_result(selection)
        Gql::ZammadSchema.execute(list_query, variables: selection.except(:targetLocale, :generateMissing, :includeContent), context: { current_user: agent }).to_h
      end

      def expect_same_selection(selection)
        response = list_result(selection)
        expect(response['errors']).to be_nil
        expected_ids = response['data'].values.flat_map { |connection| connection['edges'].pluck('node').pluck('id') }.uniq

        gql.execute(query, variables: selection)

        expect(gql.result.data[:pendingArticleIds]).to match_array(expected_ids)
        expect(gql.result.data[:results].map { |entry| entry['article']['id'] }).to match_array(expected_ids)
        expect(gql.result.data[:results].pluck('translated')).to all(be_nil)
      end

      it 'selects the same leading and trailing pages' do
        expect_same_selection(variables.merge(firstArticlesCount: 2, pageSize: 3))
      end

      it 'deduplicates overlapping pages' do
        expect_same_selection(variables.merge(firstArticlesCount: 5, pageSize: 5))
        expect(ContentTranslationJob).to have_been_enqueued.exactly(8).times
      end

      %i[beforeCursor afterCursor].each do |cursor_argument|
        it "selects the same page with #{cursor_argument}" do
          cursor = list_result(variables)['data']['articles']['edges'].first['cursor']
          expect_same_selection(variables.merge(loadFirstArticles: false, cursor_argument => cursor))
        end
      end

      it 'keeps an empty page empty' do
        expect_same_selection(variables.merge(firstArticlesCount: 0, pageSize: 0))
      end

      it 'uses the same defaults when pagination is omitted' do
        expect_same_selection(variables.except(:pageSize))
      end

      it 'uses the schema connection limits' do
        allow(Gql::ZammadSchema).to receive(:default_max_page_size).and_return(3)
        expect_same_selection(variables.merge(firstArticlesCount: 1, pageSize: 100))
      end

      it 'does not backfill excluded notices with articles outside the page' do
        articles.last.update!(preferences: { delivery_message: true })
        gql.execute(query, variables: variables.merge(loadFirstArticles: false))

        expect(gql.result.data[:pendingArticleIds]).to eq([gql.id(articles[-2])])
      end

      it 'handles invalid cursors like the article query' do
        selection = variables.merge(beforeCursor: 'invalid cursor')
        response = list_result(selection)
        gql.execute(query, variables: selection)

        expect(gql.result.payload[:errors].pluck('message')).to eq(response['errors'].pluck('message'))
      end
    end

    context 'when the agent may not translate automatically' do
      before { Setting.set('content_translation_ticket_article_auto', false) }

      it 'refuses the request' do
        gql.execute(query, variables:)

        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end
  end

  context 'when a customer asks for a translation' do
    let(:customer) { create(:customer) }
    let(:ticket)   { create(:ticket, customer:) }

    it 'is not allowed', authenticated_as: :customer do
      gql.execute(query, variables:)

      expect(gql.result.error_type).to eq(Exceptions::Forbidden)
    end
  end

  context 'when the agent may not see the ticket' do
    let(:other_agent) { create(:agent) }

    it 'fails with an error', authenticated_as: :other_agent do
      gql.execute(query, variables:)

      expect(gql.result.error_type).to eq(Exceptions::Forbidden)
    end
  end

  context 'when unauthenticated' do
    before { gql.execute(query, variables:) }

    it_behaves_like 'graphql responds with error if unauthenticated'
  end
end
