# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# The behaviour is covered by spec/services/service/user/content_translation_target_locale_spec.rb.
RSpec.describe Gql::Mutations::User::Current::ContentTranslationTargetLocale, type: :graphql do
  let(:query) do
    <<~QUERY
      mutation userCurrentContentTranslationTargetLocale($targetLocale: String!) {
        userCurrentContentTranslationTargetLocale(targetLocale: $targetLocale) {
          success
          errors {
            message
            field
          }
        }
      }
    QUERY
  end
  let(:target_locale) { 'de-de' }
  let(:variables)     { { targetLocale: target_locale } }

  context 'when logged in as an agent', authenticated_as: :agent do
    let(:agent) { create(:agent) }

    before { gql.execute(query, variables:) }

    it 'succeeds' do
      expect(gql.result.data[:success]).to be(true)
    end

    it 'hands the locale to the service' do
      expect(agent.reload.preferences['content_translation_target_locale']).to eq('de-de')
    end

    context 'with a locale the service refuses' do
      let(:target_locale) { 'xx-xx' }

      it 'fails' do
        expect(gql.result.error_type).to eq(ActiveRecord::RecordNotFound)
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
