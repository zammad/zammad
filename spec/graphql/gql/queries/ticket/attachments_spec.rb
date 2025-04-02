# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::Ticket::Attachments, authenticated_as: :user, type: :graphql do
  let(:query) do
    <<~QUERY
      query ticketAttachments($ticketId: ID!) {
        ticketAttachments(ticketId: $ticketId) {
          id
          internalId
          name
          size
          type
          preferences
        }
      }
    QUERY
  end

  let(:ticket) { create(:ticket) }
  let(:cid)    { "#{SecureRandom.uuid}@zammad.example.com" }

  let(:attachment_file_type)    { 'image/jpeg' }
  let(:attachment_content_type) { attachment_file_type }
  let(:attachment_mime_type)    { attachment_file_type }

  let(:articles) do
    create_list(:ticket_article, 2, ticket: ticket, content_type: 'text/html', body: "<img src=\"cid:#{cid}\"> some text") do |article, _i|
      create(
        :store,
        object:      'Ticket::Article',
        o_id:        article.id,
        data:        'fake',
        filename:    'inline_image.jpg',
        preferences: {
          'Content-Type'        => attachment_content_type,
          'Mime-Type'           => attachment_mime_type,
          'Content-ID'          => "<#{cid}>",
          'Content-Disposition' => 'inline',
        }
      )
      create(
        :store,
        object:      'Ticket::Article',
        o_id:        article.id,
        data:        'fake',
        filename:    'attached_image.jpg',
        preferences: {
          'Content-Type' => attachment_content_type,
          'Mime-Type'    => attachment_mime_type,
          'Content-ID'   => "<#{cid}.not.referenced>",
        }
      )
    end
  end

  let(:variables) { { ticketId: gql.id(ticket) } }

  context 'when an agent is fetching ticket attachments' do
    let(:user) { create(:agent, groups: [ticket.group]) }

    before do
      articles
      gql.execute(query, variables: variables)
    end

    it 'returns the ticket attachments' do
      expect(gql.result.data).to include(hash_including(
                                           'id'         => gql.id(articles.first.attachments.last),
                                           'internalId' => articles.first.attachments.last.id,
                                           'name'       => 'attached_image.jpg',
                                           'type'       => attachment_file_type,
                                         ))
    end

    context 'when the attachment has mime type only' do
      let(:attachment_content_type) { nil }

      it 'returns inferred attachment file type' do
        expect(gql.result.data).to include(hash_including(
                                             'type' => attachment_file_type,
                                           ))
      end
    end

    context 'when the ticket is in a group the agent is not a member of' do
      let(:user) { create(:agent, groups: []) }

      it 'returns an error' do
        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end
  end

  context 'when a customer is fetching ticket attachments' do
    let(:user) { create(:customer) }

    context 'when no access to the ticket' do
      before do
        articles
        gql.execute(query, variables: variables)
      end

      it 'returns an error' do
        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end

    context 'when access to the ticket' do
      context 'when all articles are public' do
        before do
          ticket.update!(customer: user)
          articles.each { |article| article.update!(internal: false) }
          gql.execute(query, variables: variables)
        end

        it 'returns the ticket attachments' do
          expect(gql.result.data).to include(hash_including(
                                               'id'         => gql.id(articles.first.attachments.last),
                                               'internalId' => articles.first.attachments.last.id,
                                               'name'       => 'attached_image.jpg',
                                             ))
        end
      end

      context 'when some articles are internal' do
        before do
          ticket.update!(customer: user)
          articles.each { |article| article.update!(internal: true) }
          gql.execute(query, variables: variables)
        end

        it 'returns the ticket attachments (empty)' do
          expect(gql.result.data).to eq([])
        end
      end
    end
  end

  context 'when not authenticated' do
    let(:user) { nil }

    before do
      gql.execute(query, variables: variables)
    end

    it_behaves_like 'graphql responds with error if unauthenticated'
  end
end
