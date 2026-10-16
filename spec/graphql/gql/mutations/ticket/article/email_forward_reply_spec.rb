# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# The quoted header lines are covered by spec/services/service/ticket/article/quoted_header_spec.rb.
RSpec.describe Gql::Mutations::Ticket::Article::EmailForwardReply, :aggregate_failures, type: :graphql do
  let(:article)  { create(:ticket_article, :inbound_email, :with_attachment, from: customer.email) }
  let(:agent)    { create(:agent, groups: [article.ticket.group]) }
  let(:customer) { create(:customer) }
  let(:form_id)  { SecureRandom.uuid }

  let(:query) do
    <<~QUERY
      mutation ticketArticleEmailForwardReply($articleId: ID!, $formId: FormId!) {
        ticketArticleEmailForwardReply(articleId: $articleId, formId: $formId) {
          quotableFrom
          quotableTo
          quotableCc
          attachments {
            name
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
      formId:    form_id
    }
  end

  context 'when logged in as an agent', authenticated_as: :agent do

    context 'when quoting is enabled' do
      it 'returns the quoted header lines and the cloned attachments' do
        gql.execute(query, variables: variables)

        expect(gql.result.data).to include(
          'quotableFrom' => "#{customer.fullname} <#{customer.email}>",
          'quotableTo'   => article.to,
          'quotableCc'   => nil,
          'attachments'  => [ { 'name' => article.attachments.first.filename } ],
        )
      end
    end

    context 'when quoting is disabled' do
      before do
        Setting.set('ui_ticket_zoom_article_email_full_quote_header', false)
      end

      it 'returns the cloned attachments only' do
        gql.execute(query, variables: variables)

        expect(gql.result.data).to include(
          'quotableFrom' => nil,
          'quotableTo'   => nil,
          'quotableCc'   => nil,
          'attachments'  => [ { 'name' => article.attachments.first.filename } ],
        )
      end
    end

    context 'when no form_id is given' do
      let(:variables) { { articleId: gql.id(article) } }

      it 'rejects the request' do
        gql.execute(query, variables: variables)

        expect(gql.result.error_message).to include('formId')
      end
    end

    # A blank form_id skips the upload cache authorization - it must not clone
    #   into a cache keyed by the empty string either.
    context 'when the form_id is blank' do
      let(:variables) { { articleId: gql.id(article), formId: '' } }

      it 'skips the attachment cloning' do
        gql.execute(query, variables: variables)

        expect(gql.result.data).to include('attachments' => [])
      end
    end

    context 'when form_id points to another users cache' do
      let(:other_agent) { create(:agent) }

      before do
        UploadCache.new(form_id).add(
          filename:      'intruder.txt',
          data:          'Intruder content',
          preferences:   { 'Content-Type' => 'text/plain' },
          created_by_id: other_agent.id,
        )
      end

      it 'forbids cloning attachments into another users cache' do
        expect { gql.execute(query, variables: variables) }.not_to change(Store, :count)
        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end

  end

  context 'when logged in as customer', authenticated_as: :customer do
    before do
      gql.execute(query, variables: variables)
    end

    it_behaves_like 'graphql responds with forbidden'
  end

  # The required ticket.agent permission must reject even the ticket's own
  #   customer, who would pass the article visibility check.
  context 'when logged in as the ticket customer', authenticated_as: :customer do
    let(:article)  { create(:ticket_article, :inbound_email) }
    let(:customer) { article.ticket.customer }

    before do
      gql.execute(query, variables: variables)
    end

    it_behaves_like 'graphql responds with forbidden'
  end

  context 'when not logged in' do
    before do
      gql.execute(query, variables: variables)
    end

    it_behaves_like 'graphql responds with error if unauthenticated'
  end
end
