# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::Ticket::Article::HighlightedTextUpsert, :aggregate_failures, type: :graphql do
  let(:article) { create(:ticket_article) }
  let(:agent)   { create(:agent, groups: [article.ticket.group]) }

  let(:highlight_data) do
    [
      {
        'startIndex' => 21,
        'endIndex'   => 26,
        'colorClass' => 'highlight-yellow',
      },
      {
        'startIndex' => 30,
        'endIndex'   => 35,
        'colorClass' => 'highlight-green',
      },
    ]
  end

  let(:highlight_result) { "type:TextRange|21$26$1$highlight-Yellow$article-content-#{article.id}|30$35$2$highlight-Green$article-content-#{article.id}" }

  let(:query) do
    <<~QUERY
      mutation ticketArticleHighlightedTextUpsert(
        $articleId: ID!
        $highlight: [TicketArticleHighlightedTextInput!]
      ) {
        ticketArticleHighlightedTextUpsert(articleId: $articleId, highlight: $highlight) {
          success
          errors {
            message
            field
          }
        }
      }
    QUERY
  end

  let(:variables) do
    {
      articleId: gql.id(article),
      highlight: highlight_data,
    }
  end

  context 'when logged in as an agent', authenticated_as: :agent do
    it 'stores the highlight data in article preferences' do
      gql.execute(query, variables: variables)

      expect(gql.result.data).to include('success' => true)
      expect(article.reload.preferences['highlight']).to eq(highlight_result)
    end

    context 'when highlight is nil (clearing highlights)' do
      let(:variables) do
        {
          articleId: gql.id(article),
          highlight: nil,
        }
      end

      it 'clears the highlight data in article preferences' do
        article.preferences['highlight'] = highlight_result
        article.save!

        gql.execute(query, variables: variables)

        expect(article.reload.preferences['highlight']).to be_nil
      end
    end

    context 'when the agent has no access to the ticket group' do
      let(:agent) { create(:agent) }

      before { gql.execute(query, variables: variables) }

      it 'returns a forbidden error' do
        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end
  end

  context 'when not logged in' do
    before do
      gql.execute(query, variables: variables)
    end

    it_behaves_like 'graphql responds with error if unauthenticated'
  end
end
