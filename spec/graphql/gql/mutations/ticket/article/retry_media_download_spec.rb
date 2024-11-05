# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::Ticket::Article::RetryMediaDownload, :aggregate_failures, type: :graphql do
  let(:query) do
    <<~QUERY
      mutation ticketArticleRetryMediaDownload($articleId: ID!) {
        ticketArticleRetryMediaDownload(articleId: $articleId) {
          success
          errors {
            message
            field
          }
        }
      }
    QUERY
  end

  let(:group)     { create(:group) }
  let(:agent)     { create(:agent, groups: [group]) }
  let(:customer)  { create(:customer) }
  let(:channel)   { create(:whatsapp_channel) }
  let(:ticket)    { create(:ticket, group:, preferences: { channel_id: channel.id }) }
  let(:article) do
    create(:whatsapp_article, :with_attachment_media_document, ticket: ticket, created_by: customer).tap do |article|
      article.preferences[:whatsapp][:media_error] = true
      article.save!
      article.attachments.delete_all
    end
  end

  let(:variables) { { articleId: gql.id(article) } }

  context "when retrying an article's media download" do
    context 'with an agent', authenticated_as: :agent do
      context 'with a whatsapp article with failed media download' do
        it 'creates the attachment' do
          expect_any_instance_of(Whatsapp::Retry::Media).to receive(:process).and_return(true) # rubocop:disable RSpec/StubbedMock
          gql.execute(query, variables: variables)
          expect(gql.result.data[:success]).to be true
        end
      end

      context 'with a whatsapp article without failed media download' do
        it 'returns a user error' do
          article.preferences.delete(:whatsapp)
          article.save!
          gql.execute(query, variables: variables)
          expect(gql.result.data[:success]).not_to be true
          expect(gql.result.data[:errors].first).to include(
            { 'message' => 'Retrying to download the sent media via WhatsApp failed. The given article is not a media article.' }
          )
        end
      end
    end

    context 'with a customer', authenticated_as: :customer do
      it 'raises an error' do
        gql.execute(query, variables: variables)
        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end
  end
end
