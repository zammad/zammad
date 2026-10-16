# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# The quoted header lines are covered by spec/services/service/ticket/article/quoted_header_spec.rb.
RSpec.describe Gql::Queries::Ticket::Article::QuotedHeader, type: :graphql do
  # Create as the customer - otherwise the fill-up hook makes user 1 the author.
  let(:article) do
    UserInfo.with_user_id(customer.id) do
      create(:ticket_article, :inbound_email, from: customer.email)
    end
  end
  let(:agent)    { create(:agent, groups: [article.ticket.group]) }
  let(:customer) { create(:customer) }

  let(:query) do
    <<~QUERY
      query ticketArticleQuotedHeader($articleId: ID!) {
        ticketArticleQuotedHeader(articleId: $articleId) {
          from
          to
          cc
          authorName
        }
      }
    QUERY
  end

  let(:variables) { { articleId: gql.id(article) } }

  context 'when logged in as an agent', authenticated_as: :agent do
    it 'returns the quoted header lines' do
      gql.execute(query, variables: variables)

      expect(gql.result.data).to eq(
        'from'       => "#{customer.fullname} <#{customer.email}>",
        'to'         => article.to,
        'cc'         => nil,
        'authorName' => customer.display_name_from_parts,
      )
    end

    context 'when quoting is switched off' do
      before { Setting.set('ui_ticket_zoom_article_email_full_quote_header', false) }

      it 'is not allowed' do
        gql.execute(query, variables: variables)

        expect(gql.result.error_message).to eq('This feature is not enabled.')
      end
    end

    context 'when the agent has no access to the ticket' do
      let(:agent) { create(:agent) }

      it 'is not allowed' do
        gql.execute(query, variables: variables)

        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end
  end

  # The required ticket.agent permission must reject even the ticket's own
  #   customer, who would pass the article visibility check.
  context 'when logged in as the ticket customer', authenticated_as: :customer do
    let(:article)  { create(:ticket_article, :inbound_email) }
    let(:customer) { article.ticket.customer }

    it 'is not allowed' do
      gql.execute(query, variables: variables)

      expect(gql.result.error_type).to eq(Exceptions::Forbidden)
    end
  end

  context 'when unauthenticated' do
    before { gql.execute(query, variables: variables) }

    it_behaves_like 'graphql responds with error if unauthenticated'
  end
end
