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

  def store_translation(content, backend: 'ai')
    AI::StoredResult.create!(
      content:,
      metadata:         { 'backend' => backend },
      version:          Service::AI::Feature::Translate.lookup_version({ html: true, body: article.body }, locale),
      ai_analytics_run: create(:ai_analytics_run, related_object: article),
      **Service::AI::Feature::Translate.lookup_attributes({ object: article }, locale)
    )
  end

  context 'when logged in as an agent', authenticated_as: :agent do
    before do
      setup_ai_provider
      setup_content_translation
    end

    context 'with a stored translation' do
      before { store_translation('<p>Hallo Welt.</p>') }

      it 'returns it without a background job' do
        expect { gql.execute(query, variables:) }.not_to have_enqueued_job(ContentTranslationJob)

        expect(gql.result.data[:translation])
          .to include('content' => '<p>Hallo Welt.</p>', 'backend' => 'ai', 'translated' => true)
      end

      it 'returns the analytics run for the feedback widget' do
        gql.execute(query, variables:)

        expect(gql.result.data[:analytics][:run]).to include('id' => be_present)
      end

      it 'exposes the run as related to the ticket of the article' do
        gql.execute(query, variables:)

        expect(gql.result.data[:analytics][:run]).to include('relatedObject' => { 'id' => gql.id(ticket) })
      end

      it 'returns the feedback the current user gave' do
        create(:ai_analytics_usage, ai_analytics_run: AI::Analytics::Run.last, user: agent, rating: 1)

        gql.execute(query, variables:)

        expect(gql.result.data[:analytics][:usage]).to include('userHasProvidedFeedback' => true)
      end

      it 'records no usage before the agent gave feedback' do
        expect { gql.execute(query, variables:) }.not_to change(AI::Analytics::Usage, :count)
      end
    end

    context 'with a translation stored by another service' do
      before { store_translation('<p>Hallo Welt.</p>', backend: 'deepl') }

      it 'reuses it and names the service that produced it' do
        gql.execute(query, variables:)

        expect(gql.result.data[:translation]).to include('backend' => 'deepl')
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
