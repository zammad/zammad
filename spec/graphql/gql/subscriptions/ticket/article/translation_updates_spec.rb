# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Subscriptions::Ticket::Article::TranslationUpdates, authenticated_as: :agent, type: :graphql do
  let(:ticket)           { create(:ticket) }
  let(:article)          { create(:ticket_article, ticket:) }
  let(:agent)            { create(:agent, groups: [ticket.group]) }
  let(:target_locale)    { 'de-de' }
  let(:ai_analytics_run) { create(:ai_analytics_run, related_object: ticket) }
  let(:variables)        { { ticketId: gql.id(ticket), targetLocale: target_locale } }
  let(:mock_channel)     { build_mock_channel }

  let(:subscription) do
    <<~SUBSCRIPTION
      subscription ticketArticleTranslationUpdates($ticketId: ID!, $targetLocale: String!) {
        ticketArticleTranslationUpdates(ticketId: $ticketId, targetLocale: $targetLocale) {
          article {
            id
            translation(targetLocale: $targetLocale) { content backend translated }
          }
          translation {
            content
            backend
            translated
          }
          analytics {
            run {
              id
            }
            usage {
              userHasProvidedFeedback
            }
          }
          error {
            message
            exception
          }
        }
      }
    SUBSCRIPTION
  end

  def broadcasted(index = 0)
    mock_channel.mock_broadcasted_messages[index][:result]['data']['ticketArticleTranslationUpdates']
  end

  before do
    setup_ai_provider
    setup_content_translation

    gql.execute(subscription, variables:, context: { channel: mock_channel })
  end

  it 'subscribes' do
    expect(gql.result.data).to include('translation' => nil)
  end

  context 'when the translation job succeeded' do
    let(:service_result) do
      Service::ContentTranslation::Base::Result[
        content:       '<p>Hallo Welt.</p>',
        backend:       'ai',
        translated:    true,
        fresh:         true,
        analytics_run: ai_analytics_run,
      ]
    end

    before do
      Service::ContentTranslation::StoredTranslation.save(
        object: article, locale: Locale.find_by(locale: target_locale), content: article.body,
        html: article.content_type.include?('html'), backend: 'ai', translation: service_result.content
      )
      allow(Service::ContentTranslation::TicketArticle).to receive(:execute).and_return(service_result)

      ContentTranslationJob.new.perform(article, target_locale, service: 'Service::ContentTranslation::TicketArticle')
    end

    it 'receives the article translation and analytics', :aggregate_failures do
      expect(broadcasted['translation'])
        .to eq('content' => '<p>Hallo Welt.</p>', 'backend' => 'ai', 'translated' => true)
      expect(broadcasted['article']).to eq('id' => gql.id(article), 'translation' => broadcasted['translation'])
      expect(broadcasted['analytics']).to include('run' => { 'id' => gql.id(ai_analytics_run) })
    end

    it 'reports the feedback the subscriber gave' do
      create(:ai_analytics_usage, ai_analytics_run:, user: agent, rating: 1)

      ContentTranslationJob.new.perform(article, target_locale, service: 'Service::ContentTranslation::TicketArticle')

      expect(broadcasted(-1)['analytics']).to include('usage' => { 'userHasProvidedFeedback' => true })
    end

    it 'does not expose an obsolete result from a delayed event' do
      article.update!(body: 'Changed after translation')
      ContentTranslationJob.new.perform(article, target_locale, service: 'Service::ContentTranslation::TicketArticle')

      expect(broadcasted(-1)['article']).to include('translation' => nil)
    end
  end

  context 'when the translation references an inline image' do
    let(:cid)     { "#{SecureRandom.uuid}@zammad.example.com" }
    let(:article) { create(:ticket_article, ticket:, body: "<p>Hello</p><img src=\"cid:#{cid}\">", content_type: 'text/html') }

    before do
      create(:store, object: 'Ticket::Article', o_id: article.id, data: 'fake', filename: 'inline.jpg',
                     preferences: { 'Content-Type' => 'image/jpeg', 'Content-ID' => "<#{cid}>", 'Content-Disposition' => 'inline' })

      described_class.trigger(
        { article:, translation: { content: "<p>Hallo</p><img src=\"cid:#{cid}\">", backend: 'ai', translated: true } },
        arguments: { ticket_id: gql.id(ticket), target_locale: }
      )
    end

    it 'delivers the image URL resolved, as the mutation does' do
      expect(broadcasted['translation']['content'])
        .to eq("<p>Hallo</p><img src=\"/api/v1/ticket_attachment/#{ticket.id}/#{article.id}/#{article.attachments.first.id}?view=inline\">")
    end
  end

  context 'when the subscriber is the customer of the ticket', authenticated_as: :customer do
    let(:customer) { create(:customer) }
    let(:ticket)   { create(:ticket, customer:) }

    it 'cannot subscribe' do
      expect(gql.result.error_type).to eq(Exceptions::Forbidden)
    end
  end

  context 'when the subscriber is an agent, but the customer of this ticket', authenticated_as: :agent_and_customer do
    let(:agent_and_customer) { create(:agent_and_customer) }
    let(:ticket)             { create(:ticket, customer: agent_and_customer) }

    it 'cannot subscribe' do
      expect(gql.result.error_type).to eq(Exceptions::Forbidden)
    end
  end

  # The one path into the per-subscriber filter: an event addressed to this ticket whose article
  #   has moved on to a ticket the subscriber has no agent access to. The subscriber is agent and
  #   customer on purpose - as the customer of that ticket they would pass a #show? check.
  context 'when the event carries an article the subscriber has no agent access to', authenticated_as: :agent_and_customer do
    let(:agent_and_customer) { create(:agent_and_customer, groups: [ticket.group]) }
    let(:other_ticket)       { create(:ticket, customer: agent_and_customer) }
    let(:other_article)      { create(:ticket_article, ticket: other_ticket) }

    before do
      described_class.trigger(
        { article: other_article, translation: { content: '<p>Hallo Welt.</p>', backend: 'ai', translated: true } },
        arguments: { ticket_id: gql.id(ticket), target_locale: }
      )
    end

    it 'receives nothing' do
      expect(mock_channel.mock_broadcasted_messages).to be_empty
    end
  end

  # The job publishes an event without a translation when the service produced nothing usable.
  context 'when the translation job produced nothing' do
    before do
      allow(Service::ContentTranslation::TicketArticle).to receive(:execute).and_return(nil)

      ContentTranslationJob.new.perform(article, target_locale, service: 'Service::ContentTranslation::TicketArticle')
    end

    it 'delivers no translation, not an empty one' do
      expect(broadcasted).to include('article' => { 'id' => gql.id(article), 'translation' => nil }, 'translation' => nil, 'error' => nil)
    end
  end

  context 'when the translation job failed' do
    before do
      allow(Rails.logger).to receive(:error)
      allow(Service::ContentTranslation::TicketArticle).to receive(:execute).and_raise(StandardError, 'some error')

      ContentTranslationJob.new.perform(article, target_locale, service: 'Service::ContentTranslation::TicketArticle')
    end

    it 'receives the error' do
      expect(broadcasted['error']).to eq('message' => 'some error', 'exception' => 'StandardError')
    end
  end

end
