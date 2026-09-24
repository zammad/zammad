# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::Ticket::Article::Translate, :aggregate_failures, performs_jobs: true, type: :graphql do
  let(:ticket)        { create(:ticket) }
  let(:article)       { create(:ticket_article, ticket:, body: '<p>Hello world.</p>', content_type: 'text/html') }
  let(:agent)         { create(:agent, groups: [ticket.group]) }
  let(:target_locale) { 'de-de' }
  let(:locale)        { Locale.find_by(locale: target_locale) }

  let(:query) do
    <<~MUTATION
      mutation ticketArticleTranslate($articleId: ID!, $targetLocale: String!, $force: Boolean) {
        ticketArticleTranslate(articleId: $articleId, targetLocale: $targetLocale, force: $force) {
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
              relatedObject {
                id
              }
            }
            usage {
              userHasProvidedFeedback
            }
          }
        }
      }
    MUTATION
  end

  let(:variables) { { articleId: gql.id(article), targetLocale: target_locale } }

  def store_translation(translation)
    Service::ContentTranslation::StoredTranslation.save(
      object:        article,
      locale:,
      content:       article.body,
      html:          true,
      backend:       'ai',
      translation:,
      analytics_run: create(:ai_analytics_run, related_object: article),
    )
  end

  context 'when logged in as an agent', authenticated_as: :agent do
    before do
      setup_ai_provider
      setup_content_translation
    end

    context 'with a stored translation' do
      before { store_translation('<p>Hallo Welt.</p>') }

      it 'returns it without a background job or a second stored-result lookup' do
        allow(Service::ContentTranslation::TicketArticle).to receive(:stored_translations).and_call_original
        expect { gql.execute(query, variables:) }.not_to have_enqueued_job(ContentTranslationJob)

        expect(gql.result.data[:translation])
          .to include('content' => '<p>Hallo Welt.</p>', 'backend' => 'ai', 'translated' => true)
        expect(gql.result.data[:article][:translation]).to eq(gql.result.data[:translation])
        expect(Service::ContentTranslation::TicketArticle).not_to have_received(:stored_translations)
        expect(gql.result.data[:analytics][:run]).to include('id' => be_present, 'relatedObject' => { 'id' => gql.id(ticket) })
        expect(AI::Analytics::Usage.where(user: agent)).to be_empty
      end

      it 'keeps a stored manual translation available when automatic translation skips the article' do
        article.update!(detected_language: 'de')
        gql.execute(query, variables:)

        expect(gql.result.data[:translation]['translated']).to be(false)
        expect(gql.result.data[:article][:translation]['content']).to eq('<p>Hallo Welt.</p>')
      end

      it 'returns the feedback the current user gave' do
        create(:ai_analytics_usage, ai_analytics_run: AI::Analytics::Run.last, user: agent, rating: 1)

        gql.execute(query, variables:)

        expect(gql.result.data[:analytics][:usage]).to include('userHasProvidedFeedback' => true)
      end
    end

    context 'with a stored translation referencing an inline image' do
      let(:cid)     { "#{SecureRandom.uuid}@zammad.example.com" }
      let(:article) { create(:ticket_article, ticket:, body: "<p>Hello</p><img src=\"cid:#{cid}\">", content_type: 'text/html') }

      before do
        create(:store, object: 'Ticket::Article', o_id: article.id, data: 'fake', filename: 'inline.jpg',
                       preferences: { 'Content-Type' => 'image/jpeg', 'Content-ID' => "<#{cid}>", 'Content-Disposition' => 'inline' })
        store_translation("<p>Hallo</p><img src=\"cid:#{cid}\">")
      end

      it 'answers with the image URL resolved, as in the display body of the article' do
        gql.execute(query, variables:)

        expect(gql.result.data[:translation]['content'])
          .to eq("<p>Hallo</p><img src=\"/api/v1/ticket_attachment/#{ticket.id}/#{article.id}/#{article.attachments.first.id}?view=inline\">")
      end
    end

    context 'without a stored translation' do
      it 'returns no translation yet' do
        gql.execute(query, variables:)

        expect(gql.result.data[:translation]).to be_nil
      end
    end

    context 'when the article is already in the target language' do
      let(:article) { create(:ticket_article, ticket:, body: '<p>Hallo Welt.</p>', content_type: 'text/html', detected_language: 'de') }

      it 'answers with the untranslated article' do
        gql.execute(query, variables:)

        expect(gql.result.data[:translation]).to include('translated' => false)
      end
    end

    context 'when the agent asks to translate anyway' do
      it 'passes the flag to the service' do
        allow(Service::ContentTranslation::TicketArticle).to receive(:execute)

        gql.execute(query, variables: variables.merge(force: true))

        expect(Service::ContentTranslation::TicketArticle)
          .to have_received(:execute).with(hash_including(force: true))
      end
    end

    context 'when the AI provider is not configured' do
      before { unset_ai_provider }

      it 'fails with an error' do
        gql.execute(query, variables:)

        expect(gql.result.error_message).to eq('AI provider is not configured.')
      end
    end

    context 'with a translation service that answers in place' do
      let(:url) { 'https://translate.example.com' }

      before do
        stub_request(:get, "#{url}/languages")
          .to_return(status: 200, body: [{ code: 'en' }, { code: 'de' }].to_json, headers: { 'Content-Type' => 'application/json' })
        stub_request(:post, "#{url}/translate")
          .to_return(status: 200, body: { translatedText: '<p>Hallo Welt.</p>' }.to_json, headers: { 'Content-Type' => 'application/json' })

        setup_content_translation(provider: 'libre_translate', url:)
      end

      it 'answers with the translation and an analytics run' do
        gql.execute(query, variables:)

        expect(gql.result.data[:translation])
          .to include('content' => '<p>Hallo Welt.</p>', 'backend' => 'libre_translate', 'translated' => true)
        expect(gql.result.data[:analytics][:run]).to include('id' => be_present)
      end
    end

    # LibreTranslate answers in place rather than through the subscription, so the mutation is where
    # a failed translation becomes visible to the client.
    context 'with a target locale the translation service does not support' do
      let(:url) { 'https://translate.example.com' }

      before do
        # Saving the config runs the connection test, so the instance has to answer beforehand -
        # the listing and the translation it probes with.
        stub_request(:get, "#{url}/languages")
          .to_return(status: 200, body: [{ code: 'en' }, { code: 'fr' }].to_json, headers: { 'Content-Type' => 'application/json' })
        stub_request(:post, "#{url}/translate")
          .to_return(status: 200, body: { translatedText: 'Zammad' }.to_json, headers: { 'Content-Type' => 'application/json' })

        setup_content_translation(provider: 'libre_translate', url:)
      end

      it 'fails with the outcome instead of answering with the article' do
        gql.execute(query, variables:)

        expect(gql.result.error_type).to eq(Service::ContentTranslation::Backend::Base::UnsupportedLanguageError)
        expect(gql.result.error_message).to include(target_locale)
      end
    end
  end

  context 'when a customer asks for a translation' do
    let(:customer) { create(:customer) }
    let(:ticket)   { create(:ticket, customer:) }

    it 'is not allowed', authenticated_as: :customer do
      gql.execute(query, variables:)

      expect(gql.result.error_type).to eq(Exceptions::Forbidden)
    end
  end

  context 'when the requesting agent is the customer of the ticket, outside of their groups' do
    let(:agent_and_customer) { create(:agent_and_customer) }
    let(:ticket)             { create(:ticket, customer: agent_and_customer) }

    it 'is not allowed', authenticated_as: :agent_and_customer do
      gql.execute(query, variables:)

      expect(gql.result.error_type).to eq(Exceptions::Forbidden)
    end
  end

  context 'when the agent may not see the article' do
    let(:other_agent) { create(:agent) }

    it 'fails with an error', authenticated_as: :other_agent do
      gql.execute(query, variables:)

      expect(gql.result.error_type).to eq(Exceptions::Forbidden)
    end
  end

  context 'when unauthenticated' do
    before { gql.execute(query, variables:) }

    it_behaves_like 'graphql responds with error if unauthenticated'
  end
end
