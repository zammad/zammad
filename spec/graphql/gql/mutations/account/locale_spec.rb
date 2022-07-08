# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::Account::Locale, type: :graphql do

  context 'when updating language of the logged-in user', authenticated_as: :agent do
    let(:agent)        { create(:agent, preferences: { 'locale' => 'de-de' }) }
    let(:query)        do
      read_graphql_file('apps/mobile/modules/account/graphql/locale.graphql') +
        read_graphql_file('shared/graphql/fragments/errors.graphql')
    end
    let(:locale_id) { Gql::ZammadSchema.id_from_object(Locale.find_by(locale: 'en-us')) }
    let(:variables) { { localeId: locale_id } }

    before do
      graphql_execute(query, variables: variables)
    end

    context 'with valid locale' do
      it 'returns success' do
        expect(graphql_response['data']['accountLocale']['success']).to be true
      end

      it 'updates the locale' do
        expect(agent.reload.preferences['locale']).to eq('en-us')
      end
    end

    context 'with invalid locale' do
      let(:locale_id) { Gql::ZammadSchema.id_from_object(Ticket.first) }

      it 'fails with error message' do
        expect(graphql_response['errors'][0]).to include('message' => 'Locale could not be found.')
      end

      it 'fails with error type' do
        expect(graphql_response['errors'][0]['extensions']).to include({ 'type' => 'ActiveRecord::RecordNotFound' })
      end
    end

    it_behaves_like 'graphql responds with error if unauthenticated'
  end
end
