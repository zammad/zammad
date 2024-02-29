# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

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

      let(:expected_response) do
        {
          'quotableFrom' => "#{customer.fullname} <#{customer.email}>",
          'quotableTo'   => article.to,
          'quotableCc'   => nil,
          'attachments'  => [ { 'name' => article.attachments.first.filename } ],
        }
      end

      it 'includes personal data' do
        gql.execute(query, variables: variables)

        expect(gql.result.data).to include(expected_response)
      end
    end

    context 'when quoting is disabled' do

      before do
        Setting.set('ui_ticket_zoom_article_email_full_quote_header', false)
      end

      let(:expected_response) do
        {
          'quotableFrom' => nil,
          'quotableTo'   => nil,
          'quotableCc'   => nil,
          'attachments'  => [ { 'name' => article.attachments.first.filename } ],
        }
      end

      it 'does not include personal data' do
        gql.execute(query, variables: variables)

        expect(gql.result.data).to include(expected_response)
      end
    end

  end

  context 'when logged in as customer', authenticated_as: :customer do
    before do
      gql.execute(query, variables: variables)
    end

    it_behaves_like 'graphql responds with error if unauthenticated'
  end

  context 'when not logged in' do
    before do
      gql.execute(query, variables: variables)
    end

    it_behaves_like 'graphql responds with error if unauthenticated'
  end

  describe '#quotableFrom', authenticated_as: :agent do
    let(:expected_response) do
      nil
    end

    context 'when origin_by is set' do
      let(:user) { create(:agent) }
      let(:article) { create(:ticket_article, origin_by: user) }

      let(:expected_response) do
        user.fullname
      end

      it 'works as expected' do
        gql.execute(query, variables: variables)
        expect(gql.result.data['quotableFrom']).to eq(expected_response)
      end
    end

    context 'when created_by is set' do
      let(:user) { create(:agent) }
      let(:article) { create(:ticket_article, created_by: user) }

      let(:expected_response) do
        user.fullname
      end

      it 'works as expected' do
        gql.execute(query, variables: variables)
        expect(gql.result.data['quotableFrom']).to eq(expected_response)
      end
    end
  end

  describe '#quotableTo', authenticated_as: :agent do
    let(:expected_response) do
      nil
    end

    context 'when inbound_email is set' do
      let(:user) { create(:agent) }
      let(:article) { create(:ticket_article, :inbound_email) }

      let(:expected_response) do
        article.to
      end

      it 'works as expected' do
        gql.execute(query, variables: variables)
        expect(gql.result.data['quotableTo']).to eq(expected_response)
      end
    end

    context 'when inbound_phone is set' do
      let(:user) { create(:agent) }
      let(:article) { create(:ticket_article, :inbound_phone) }

      let(:expected_response) do
        article.to
      end

      it 'works as expected' do
        gql.execute(query, variables: variables)
        expect(gql.result.data['quotableTo']).to eq(expected_response)
      end
    end

    context 'when outbound_phone is set' do
      let(:user) { create(:customer) }
      let(:article) { create(:ticket_article, :outbound_phone, ticket: create(:ticket, customer: user)) }

      let(:expected_response) do
        "#{user.fullname} <#{user.email}>"
      end

      it 'works as expected' do
        gql.execute(query, variables: variables)
        expect(gql.result.data['quotableTo']).to eq(expected_response)
      end
    end
  end

  describe '#quotableCc', authenticated_as: :agent do
    let(:user) { create(:customer) }
    let(:article) { create(:ticket_article, cc: user.email) }

    let(:expected_response) do
      "#{user.fullname} <#{user.email}>"
    end

    it 'works as expected' do
      gql.execute(query, variables: variables)
      expect(gql.result.data['quotableCc']).to eq(expected_response)
    end
  end
end
