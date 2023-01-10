# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::Ticket::Article::ChangeVisibility, :aggregate_failures, type: :graphql do
  let(:article) { create(:ticket_article) }
  let(:agent)   { create(:agent, groups: [article.ticket.group]) }

  let(:query) do
    <<~QUERY
      mutation ticketArticleChangeVisibility($articleId: ID!, $internal: Boolean!) {
        ticketArticleChangeVisibility(articleId: $articleId, internal: $internal) {
          article {
            id
          }
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
      internal:  true
    }
  end

  context 'when logged in as an agent', authenticated_as: :agent do
    it 'delegates to the service' do
      log = []

      allow_any_instance_of(Service::Ticket::Article::ChangeVisibility)
        .to receive(:execute) do |article:, internal:|
          log << { article: article.id, internal: internal }
        end

      gql.execute(query, variables: variables)

      expect(log).to include(include(article: article.id, internal: true))
    end
  end

  context 'with GQL query' do
    before do
      gql.execute(query, variables: variables)
    end

    it_behaves_like 'graphql responds with error if unauthenticated'
  end
end
