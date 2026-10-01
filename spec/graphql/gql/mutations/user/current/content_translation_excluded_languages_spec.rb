# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# The behaviour is covered by spec/services/service/user/content_translation_excluded_languages_spec.rb.
RSpec.describe Gql::Mutations::User::Current::ContentTranslationExcludedLanguages, type: :graphql do
  let(:query) do
    <<~QUERY
      mutation userCurrentContentTranslationExcludedLanguages($languages: [String!]!) {
        userCurrentContentTranslationExcludedLanguages(languages: $languages) {
          success
          errors {
            message
            field
          }
        }
      }
    QUERY
  end

  let(:languages) { %w[en] }
  let(:variables) { { languages: } }

  context 'when logged in as an agent', authenticated_as: :agent do
    let(:agent) { create(:agent) }

    before { Setting.set('content_translation_ticket_article_auto', true) }

    it 'saves the preference and returns success', :aggregate_failures do
      gql.execute(query, variables:)

      expect(gql.result.data[:success]).to be(true)
      expect(agent.reload.preferences['content_translation_excluded_languages']).to eq(%w[en])
    end

    context 'with a language the service refuses' do
      let(:languages) { %w[xx] }

      it 'fails' do
        gql.execute(query, variables:)

        expect(gql.result.error_type).to eq(ActiveRecord::RecordNotFound)
      end
    end

    context 'with an agent the configured roles do not allow' do
      before { Setting.set('content_translation_ticket_article_auto_role_ids', [create(:role).id]) }

      it 'fails' do
        gql.execute(query, variables:)

        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end
  end

  context 'when logged in as a customer', authenticated_as: :customer do
    let(:customer) { create(:customer) }

    it 'is not allowed' do
      gql.execute(query, variables:)

      expect(gql.result.error_type).to eq(Exceptions::Forbidden)
    end
  end

  context 'when unauthenticated' do
    before { gql.execute(query, variables:) }

    it_behaves_like 'graphql responds with error if unauthenticated'
  end
end
