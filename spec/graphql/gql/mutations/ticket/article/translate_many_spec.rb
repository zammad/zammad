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
        $loadFirstArticles: Boolean, $beforeCursor: String, $afterCursor: String
      ) {
        ticketArticleTranslateMany(
          ticketId: $ticketId, targetLocale: $targetLocale, pageSize: $pageSize,
          firstArticlesCount: $firstArticlesCount, loadFirstArticles: $loadFirstArticles,
          beforeCursor: $beforeCursor, afterCursor: $afterCursor
        ) {
          pendingArticleIds
          translations {
            article {
              id
            }
            translation {
              content
              backend
              translated
            }
          }
        }
      }
    MUTATION
  end

  let(:variables) do
    {
      ticketId:     gql.id(ticket),
      pageSize:     2,
      targetLocale: target_locale,
    }
  end

  def store_translation(article, translation)
    Service::ContentTranslation::StoredTranslation.save(
      object:      article,
      locale:,
      content:     article.body,
      html:        true,
      backend:     'ai',
      translation:,
    )
  end

  context 'when logged in as an agent', authenticated_as: :agent do
    before do
      setup_ai_provider
      setup_content_translation
      Setting.set('content_translation_ticket_article_auto', true)
    end

    context 'with a stored translation of one article' do
      before { store_translation(articles.first, '<p>Hallo Welt.</p>') }

      it 'answers with it, and leaves the other one to the subscription' do
        gql.execute(query, variables:)

        expect(gql.result.data[:pendingArticleIds]).to eq([gql.id(articles.last)])
        expect(gql.result.data[:translations]).to contain_exactly(
          {
            'article'     => { 'id' => gql.id(articles.first) },
            'translation' => { 'content' => '<p>Hallo Welt.</p>', 'backend' => 'ai', 'translated' => true },
          }
        )
      end

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
        Gql::ZammadSchema.execute(list_query, variables: selection.except(:targetLocale), context: { current_user: agent }).to_h
      end

      def expect_same_selection(selection)
        response = list_result(selection)
        expect(response['errors']).to be_nil
        expected_ids = response['data'].values.flat_map { |connection| connection['edges'].pluck('node').pluck('id') }.uniq

        gql.execute(query, variables: selection)

        expect(gql.result.data[:pendingArticleIds]).to match_array(expected_ids)
        expect(gql.result.data[:translations]).to be_empty
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
