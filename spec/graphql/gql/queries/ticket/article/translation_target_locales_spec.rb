# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# The locale filtering is covered by spec/services/service/content_translation/target_locales_spec.rb.
RSpec.describe Gql::Queries::Ticket::Article::TranslationTargetLocales, type: :graphql do
  let(:agent) { create(:agent) }
  let(:query) do
    <<~QUERY
      query ticketArticleTranslationTargetLocales {
        ticketArticleTranslationTargetLocales {
          locale
          alias
          name
          dir
        }
      }
    QUERY
  end

  before do
    setup_ai_provider
    setup_content_translation
  end

  context 'when logged in as an agent', authenticated_as: :agent do
    before { gql.execute(query) }

    it 'returns the supported locales without anything about the service configuration' do
      expect(gql.result.data).to include(
        'locale' => 'de-de',
        'alias'  => 'de',
        'name'   => 'Deutsch - German',
        'dir'    => 'ltr',
      )
    end

    context 'when article translation is switched off' do
      before { Setting.set('content_translation_ticket_article', false) }

      it 'is not allowed' do
        gql.execute(query)

        expect(gql.result.error_message).to eq('Ticket article translation is not enabled.')
      end
    end

    context 'when the AI provider is not configured' do
      before { unset_ai_provider }

      it 'reaches the client as an error' do
        gql.execute(query)

        expect(gql.result.error_message).to eq('AI provider is not configured.')
      end
    end

    context 'when the service raises an error' do
      before { allow(Service::ContentTranslation::Backend).to receive(:configured).and_return(nil) }

      it 'reaches the client as an error' do
        gql.execute(query)

        expect(gql.result.error_message).to eq('The configured translation service is not available.')
      end
    end
  end

  context 'when logged in as a customer', authenticated_as: :customer do
    let(:customer) { create(:customer) }

    it 'is not allowed' do
      gql.execute(query)

      expect(gql.result.error_type).to eq(Exceptions::Forbidden)
    end
  end

  context 'when unauthenticated' do
    before { gql.execute(query) }

    it_behaves_like 'graphql responds with error if unauthenticated'
  end
end
