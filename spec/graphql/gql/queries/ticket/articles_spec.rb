# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::Ticket::Articles, type: :graphql do

  context 'when fetching tickets' do
    let(:agent)                { create(:agent) }
    let(:query)                do
      <<~QUERY
        query ticketArticles($ticketId: ID!) {
          ticketArticles(ticketId: $ticketId) {
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
                highlightedTexts {
                  startIndex
                  endIndex
                  colorClass
                }
                body
                bodyWithUrls
                bodyRenderingError
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
            'bodyWithUrls'             => "<img src=\"#{inline_url}\"> some text",
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

        context 'with highlightedTexts information' do
          let(:articles) do
            create_list(
              :ticket_article, 1, :outbound_email, ticket: ticket, to: to, cc: cc,
              preferences: {
                'highlight' => 'type:TextRange|0$4$1$highlight-Green$article-content-21|13$18$2$highlight-Blue$article-content-21'
              }
            )
          end
          let(:expected_highlighted_texts) do
            [
              { 'startIndex' => 0,  'endIndex' => 4,  'colorClass' => 'highlight-green' },
              { 'startIndex' => 13, 'endIndex' => 18, 'colorClass' => 'highlight-blue' },
            ]
          end

          it 'includes highlightedTexts information' do
            expect(response_articles.first).to include({ 'highlightedTexts' => expected_highlighted_texts })
          end

          context 'with invalid highlight data' do
            let(:articles) do
              create_list(
                :ticket_article, 1, :outbound_email, ticket: ticket, to: to, cc: cc,
                preferences: {
                  'highlight' => 'type:TextRange|',
                }
              )
            end

            it 'handles invalid highlight data gracefully' do
              expect(response_articles.first).to include({ 'highlightedTexts' => [] })
            end
          end

          context 'with empty highlight data' do
            let(:articles) do
              create_list(
                :ticket_article, 1, :outbound_email, ticket: ticket, to: to, cc: cc,
                preferences: {
                  'highlight' => nil,
                }
              )
            end

            it 'handles empty highlight data gracefully' do
              expect(response_articles.first).to include({ 'highlightedTexts' => [] })
            end
          end
        end

        context 'with bodyRenderingError' do
          context 'when body is UNPROCESSABLE_HTML_MSG (string comparison fallback)' do
            let(:articles) { create_list(:ticket_article, 1, :outbound_email, ticket: ticket, body: HtmlSanitizer::UNPROCESSABLE_HTML_MSG) }

            it 'returns bodyRenderingError as true' do
              expect(response_articles.first).to include('bodyRenderingError' => true)
            end
          end

          context 'when body is EXCESSIVE_LINKS_MSG (string comparison fallback)' do
            let(:articles) { create_list(:ticket_article, 1, :outbound_email, ticket: ticket, body: Channel::EmailParser::EXCESSIVE_LINKS_MSG) }

            it 'returns bodyRenderingError as true' do
              expect(response_articles.first).to include('bodyRenderingError' => true)
            end
          end

          context 'when body_rendering_error preference is set (preference path)' do
            let(:articles) { create_list(:ticket_article, 1, :outbound_email, ticket: ticket, preferences: { 'body_rendering_error' => true }) }

            it 'returns bodyRenderingError as true regardless of body content' do
              expect(response_articles.first).to include('bodyRenderingError' => true)
            end
          end

          context 'when body is normal content' do
            it 'returns bodyRenderingError as false' do
              expect(response_articles.first).to include('bodyRenderingError' => false)
            end
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

  context 'when fetching the accounted time of articles' do
    let(:query) do
      <<~QUERY
        query ticketArticles($ticketId: ID!) {
          ticketArticles(ticketId: $ticketId) {
            edges {
              node {
                id
                timeUnit
                accountedTimeType {
                  name
                }
              }
            }
          }
        }
      QUERY
    end

    let(:customer)  { create(:customer) }
    let(:ticket)    { create(:ticket, customer:) }
    let(:agent)     { create(:agent, groups: [ticket.group]) }
    let(:variables) { { ticketId: gql.id(ticket) } }

    let(:activity_type) { create(:ticket_time_accounting_type, name: 'Billing') }

    let!(:accounted_article)   { create(:ticket_article, ticket:) }
    let!(:untyped_article)     { create(:ticket_article, ticket:) }
    let!(:unaccounted_article) { create(:ticket_article, ticket:) }
    let!(:time_accounting)     { create(:ticket_time_accounting, ticket:, ticket_article: accounted_article, time_unit: 42, type: activity_type) }

    let(:response_articles) { gql.result.nodes }

    before { create(:ticket_time_accounting, ticket:, ticket_article: untyped_article, time_unit: 7) }

    context 'with an agent', authenticated_as: :agent do
      before { gql.execute(query, variables:) }

      it 'returns the accounted time of the article' do
        expect(response_articles).to include(include('id' => gql.id(accounted_article), 'timeUnit' => time_accounting.time_unit.to_f))
      end

      it 'returns the activity type of the accounted time' do
        expect(response_articles).to include(include('id' => gql.id(accounted_article), 'accountedTimeType' => { 'name' => activity_type.name }))
      end

      it 'returns no activity type for an accounted time without one' do
        expect(response_articles).to include(include('id' => gql.id(untyped_article), 'accountedTimeType' => nil))
      end

      it 'returns no accounted time for an article without one' do
        expect(response_articles).to include(include('id' => gql.id(unaccounted_article), 'timeUnit' => nil, 'accountedTimeType' => nil))
      end
    end

    context 'with a customer', authenticated_as: :customer do
      before { gql.execute(query, variables:) }

      it 'returns no accounted time at all' do
        expect(response_articles).to include(include('id' => gql.id(accounted_article), 'timeUnit' => nil, 'accountedTimeType' => nil))
      end
    end

    context 'when many articles are accounted', authenticated_as: :agent do
      def query_count(table)
        queries = []
        subscriber = ActiveSupport::Notifications.subscribe('sql.active_record') do |*, payload|
          queries << payload[:sql] if payload[:sql].include?(table)
        end
        gql.execute(query, variables:)
        queries.size
      ensure
        ActiveSupport::Notifications.unsubscribe(subscriber)
      end

      # The accounted times and their activity types are batch loaded, so all articles are
      #   resolved with one query each, no matter how long the article list grows.
      it 'resolves the accounted times and activity types in a single query each', :aggregate_failures do
        expect(query_count('ticket_time_accountings')).to eq(1)
        expect(query_count('ticket_time_accounting_types')).to eq(1)

        create_list(:ticket_article, 3, ticket:).each do |article|
          create(:ticket_time_accounting, ticket:, ticket_article: article, time_unit: 7, type: create(:ticket_time_accounting_type))
        end

        expect(query_count('ticket_time_accountings')).to eq(1)
        expect(query_count('ticket_time_accounting_types')).to eq(1)
      end
    end
  end

  context 'when fetching stored article translations', :aggregate_failures, authenticated_as: :agent do
    let(:ticket)    { create(:ticket) }
    let(:agent)     { create(:agent, groups: [ticket.group]) }
    let!(:articles) { create_list(:ticket_article, 3, ticket:, body: '<p>Hello</p>', content_type: 'text/html') }
    let(:variables) { { ticketId: gql.id(ticket), targetLocale: 'de-de', includeContent: true } }
    let(:query) do
      <<~QUERY
        query ticketArticles($ticketId: ID!, $targetLocale: String!, $includeContent: Boolean!) {
          ticketArticles(ticketId: $ticketId) {
            edges {
              node {
                id
                translationAvailable(targetLocale: $targetLocale)
                availabilityWithoutLocale: translationAvailable
                translation(targetLocale: $targetLocale) @include(if: $includeContent) {
                  content
                  backend
                  translated
                }
              }
            }
          }
        }
      QUERY
    end

    before do
      setup_content_translation
      articles.first(2).each do |article|
        Service::ContentTranslation::StoredTranslation.save(
          object: article, locale: Locale.find_by(locale: 'de-de'), content: article.body,
          html: true, backend: 'ai', translation: '<p>Hallo</p>'
        )
      end
    end

    def stored_result_queries
      queries = []
      subscriber = ActiveSupport::Notifications.subscribe('sql.active_record') do |*, payload|
        queries << payload[:sql] if payload[:sql].include?('FROM "ai_stored_results"')
      end
      gql.execute(query, variables:)
      queries
    ensure
      ActiveSupport::Notifications.unsubscribe(subscriber)
    end

    it 'batches content reads and never generates a missing translation' do
      allow(Service::ContentTranslation::TicketArticle).to receive(:execute).and_call_original

      expect(stored_result_queries.size).to eq(2)
      expect(gql.result.nodes.first['translation']).to eq('content' => '<p>Hallo</p>', 'backend' => 'ai', 'translated' => true)
      expect(gql.result.nodes.last['translation']).to be_nil
      expect(Service::ContentTranslation::TicketArticle).not_to have_received(:execute)

      gql.execute(query, variables: variables.merge(targetLocale: 'fr-fr'))
      expect(gql.result.nodes.pluck('translation')).to all(be_nil)
    end

    it 'keeps availability-only requests free of translated bodies' do
      variables[:includeContent] = false
      queries = stored_result_queries

      expect(queries.size).to eq(1)
      expect(queries.first).not_to include('"ai_stored_results"."content"')
      expect(gql.result.nodes.first).to include('translationAvailable' => true, 'availabilityWithoutLocale' => nil)
      expect(gql.result.nodes.last).to include('translationAvailable' => false)
      expect(gql.result.nodes.first).not_to have_key('translation')
    end

    it 'does not return content when article translation is disabled' do
      Setting.set('content_translation_ticket_article', false)
      gql.execute(query, variables:)

      expect(gql.result.nodes.pluck('translation')).to all(be_nil)
    end

    context 'with a customer', authenticated_as: :customer do
      let(:customer) { create(:customer) }
      let(:ticket) { create(:ticket, customer:) }

      it 'does not expose translation content' do
        gql.execute(query, variables:)

        expect(gql.result.nodes.pluck('translation')).to all(be_nil)
      end
    end

    context 'with an agent who only has customer access', authenticated_as: :customer do
      let(:customer) { create(:agent_and_customer) }
      let(:ticket) { create(:ticket, customer:) }

      it 'does not expose translation content' do
        gql.execute(query, variables:)

        expect(gql.result.nodes.pluck('translation')).to all(be_nil)
      end
    end
  end

end
