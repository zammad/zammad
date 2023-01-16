# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::Ticket::Article::Delete, :aggregate_failures, type: :graphql do
  let(:ticket)  { create(:ticket) }
  let(:article) { create(:ticket_article, :internal_note, ticket: ticket, created_by: user) }
  let(:user)    { create(:agent, groups: [ticket.group]) }

  let(:query) do
    <<~QUERY
      mutation ticketArticleDelete($articleId: ID!) {
        ticketArticleDelete(articleId: $articleId) {
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
    }
  end

  context 'when logged in as an agent', authenticated_as: :user do
    before { article }

    it 'destroys article' do
      expect { gql.execute(query, variables: variables) }
        .to change { Ticket::Article.exists? article.id }
        .to false
    end

    context 'when article cannot be destroyed anymore' do
      before { travel 1.hour }

      it 'fails with Pundit error' do
        travel 1.hour

        expect { gql.execute(query, variables: variables) }
          .not_to change { Ticket::Article.exists? article.id }

        expect(gql.result.error_type).to eq(Pundit::NotAuthorizedError)
      end
    end
  end

  context 'with GQL query' do
    before do
      gql.execute(query, variables: variables)
    end

    it_behaves_like 'graphql responds with error if unauthenticated'
  end
end
