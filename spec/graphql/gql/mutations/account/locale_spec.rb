# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::Account::Locale, type: :graphql do

  context 'when updating language of the logged-in user', authenticated_as: :agent do
    let(:agent)        { create(:agent, preferences: { 'locale' => 'de-de' }) }
    let(:query)        do
      <<~QUERY
        mutation accountLocale($locale: String!) {
          accountLocale(locale: $locale) {
            success
            errors {
              message
              field
            }
          }
        }
      QUERY
    end
    let(:locale) { 'en-us' }
    let(:variables) { { locale: locale } }

    before do
      gql.execute(query, variables: variables)
    end

    context 'with valid locale' do
      it 'returns success' do
        expect(gql.result.data['success']).to be true
      end

      it 'updates the locale' do
        expect(agent.reload.preferences['locale']).to eq('en-us')
      end
    end

    context 'with invalid locale' do
      let(:locale) { 'nonexisting-locale' }

      it 'fails with error message' do
        expect(gql.result.error_message).to eq('Locale could not be found.')
      end

      it 'fails with error type' do
        expect(gql.result.error_type).to eq(ActiveRecord::RecordNotFound)
      end
    end

    it_behaves_like 'graphql responds with error if unauthenticated'
  end
end
