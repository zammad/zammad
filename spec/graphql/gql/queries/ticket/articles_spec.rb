# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::Ticket::Articles, type: :graphql do

  context 'when fetching tickets' do
    let(:agent)                { create(:agent) }
    let(:query)                do
      <<~QUERY
        query ticketArticles(
          $ticketId: ID
          $ticketInternalId: Int
          $ticketNumber: String
        ) {
          ticketArticles(
            ticket: {
              ticketId: $ticketId
              ticketInternalId: $ticketInternalId
              ticketNumber: $ticketNumber
            }
          ) {
            totalCount
            edges {
              node {
                id
                internalId
                from {
                  raw
                  parsed {
                    name
                    emailAddress
                    isSystemAddress
                  }
                }
                to {
                  raw
                  parsed {
                    name
                    emailAddress
                    isSystemAddress
                  }
                }
                cc {
                  raw
                  parsed {
                    name
                    emailAddress
                    isSystemAddress
                  }
                }
                subject
                replyTo {
                  raw
                  parsed {
                    name
                    emailAddress
                    isSystemAddress
                  }
                }
                messageId
                messageIdMd5
                inReplyTo
                contentType
                attachments {
                  name
                }
                attachmentsWithoutInline {
                  name
                }
                preferences
                securityState {
                  type
                  signingSuccess
                  signingMessage
                  encryptionSuccess
                  encryptionMessage
                }
                body
                bodyWithUrls
                internal
                createdAt
                author {
                  id
                  fullname
                  firstname
                  lastname
                }
                createdBy {
                  id
                  firstname
                  lastname
                  fullname
                }
                type {
                  name
                }
                sender {
                  name
                }
              }
              cursor
            }
            pageInfo {
              endCursor
              hasNextPage
            }
          }
        }
      QUERY
    end
    let(:variables)            { { ticketId: gql.id(ticket) } }
    let(:customer)             { create(:customer) }
    let(:ticket)               { create(:ticket, customer: customer) }
    let(:cc)                   { 'Zammad CI <ci@zammad.org>' }
    let(:to)                   { Faker::Internet.unique.email }
    let(:cid)                  { "#{SecureRandom.uuid}@zammad.example.com" }
    let!(:articles) do
      create_list(:ticket_article, 2, :outbound_email, ticket: ticket, to: to, cc: cc, content_type: 'text/html', body: "<img src=\"cid:#{cid}\"> some text") do |article, _i|
        create(
          :store,
          object:      'Ticket::Article',
          o_id:        article.id,
          data:        'fake',
          filename:    'inline_image.jpg',
          preferences: {
            'Content-Type'        => 'image/jpeg',
            'Mime-Type'           => 'image/jpeg',
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
            'Content-Type'        => 'image/jpeg',
            'Mime-Type'           => 'image/jpeg',
            'Content-ID'          => "<#{cid}.not.referenced>",
            'Content-Disposition' => 'inline',
          }
        )
      end
    end
    let!(:internal_article)    { create(:ticket_article, :outbound_email, ticket: ticket, internal: true) }
    let(:response_articles)    { gql.result.nodes }
    let(:response_total_count) { gql.result.data[:totalCount] }

    before do
      gql.execute(query, variables: variables)
    end

    context 'with an agent', authenticated_as: :agent do

      context 'with permission' do
        let(:agent) { create(:agent, groups: [ticket.group]) }
        let(:article1)   { articles.first }
        let(:inline_url) { "/api/v1/ticket_attachment/#{article1['ticket_id']}/#{article1['id']}/#{article1.attachments.first[:id]}?view=inline" }
        let(:expected_article1) do
          {
            'subject'                  => article1.subject,
            'cc'                       => {
              'parsed' => [
                {
                  'emailAddress'    => 'ci@zammad.org',
                  'name'            => 'Zammad CI',
                  'isSystemAddress' => false,
                },
              ],
              'raw'    => cc,
            },
            'to'                       => {
              'parsed' => [
                {
                  'emailAddress'    => to,
                  'name'            => nil,
                  'isSystemAddress' => false,
                }
              ],
              'raw'    => to,
            },
            'type'                     => {
              'name' => article1.type.name,
            },
            'sender'                   => {
              'name' => article1.sender.name,
            },
            'securityState'            => nil,
            'body'                     => "<img src=\"cid:#{cid}\"> some text",
            'bodyWithUrls'             => "<img src=\"#{inline_url}\" style=\"max-width:100%;\"> some text",
            'attachments'              => [{ 'name'=>'inline_image.jpg' }, { 'name'=>'attached_image.jpg' }],
            'attachmentsWithoutInline' => [{ 'name'=>'attached_image.jpg' }],
          }
        end

        it 'finds public and internal articles' do
          expect(response_total_count).to eq(articles.count + 1)
        end

        it 'finds article content' do
          expect(response_articles.first).to include(expected_article1)
        end

        context 'with ticketInternalId' do
          let(:variables) { { ticketInternalId: ticket.id } }

          it 'finds articles' do
            expect(response_total_count).to eq(articles.count + 1)
          end
        end

        context 'with ticketNumber' do
          let(:variables) { { ticketNumber: ticket.number } }

          it 'finds articles' do
            expect(response_total_count).to eq(articles.count + 1)
          end
        end

        context 'with securityState information' do
          let(:articles) do
            create_list(
              :ticket_article, 1, :outbound_email, ticket: ticket, to: to, cc: cc,
              preferences: {
                'security' => { 'type' => 'S/MIME', 'sign' => { 'success' => false, 'comment' => 'Message is not signed by sender.' }, 'encryption' => { 'success' => false, 'comment' => nil } }
              }
            )
          end
          let(:expected_security_state) do
            {
              'type'              => 'SMIME',
              'signingSuccess'    => false,
              'signingMessage'    => 'Message is not signed by sender.',
              'encryptionSuccess' => false,
              'encryptionMessage' => nil,
            }
          end

          it 'includes securityStatus information' do
            expect(response_articles.first).to include({ 'securityState' => expected_security_state })
          end
        end

        context 'when has originBy' do
          let(:articles) { create_list(:ticket_article, 1, :inbound_phone, ticket: ticket, origin_by: agent, created_by: create(:agent, groups: [ticket.group])) }

          it 'loads originBy' do
            expect(response_articles.first)
              .to include(
                'author'    => include('fullname' => agent.fullname),
                'createdBy' => be_present
              )
          end
        end
      end

      context 'without permission' do
        it 'raises authorization error' do
          expect(gql.result.error_type).to eq(Exceptions::Forbidden)
        end
      end

      context 'without ticket' do
        let(:ticket)           { create(:ticket).tap(&:destroy) }
        let(:articles)         { [] }
        let(:internal_article) { [] }

        it 'fetches no ticket' do
          expect(gql.result.error_type).to eq(ActiveRecord::RecordNotFound)
        end
      end
    end

    context 'with a customer', authenticated_as: :customer do
      let(:variables) { { ticketId: gql.id(ticket) } }

      it 'finds only public articles' do
        expect(response_total_count).to eq(articles.count)
      end

      it 'does not find internal articles' do
        expect(response_articles.pluck(:id)).to not_include(internal_article.id)
      end

      context 'when has originBy' do
        let(:origin_by) { create(:agent) }

        let(:articles) do
          create_list(:ticket_article, 1, :inbound_phone, ticket: ticket, origin_by: origin_by, created_by: create(:agent, groups: [ticket.group]))
        end

        it 'loads originBy' do
          expect(response_articles.first)
            .to include(
              'author'    => include(
                'fullname'  => nil, # fullname is filtered out for customers
                'firstname' => origin_by.firstname
              ),
              'createdBy' => be_present
            )
        end
      end
    end

    it_behaves_like 'graphql responds with error if unauthenticated'
  end
end
