# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::Translations, type: :graphql do

  context 'when fetching translations' do
    let(:query) { read_graphql_file('common/graphql/queries/translations.graphql') }
    let(:variables) { { locale: locale, cacheKey: cache_key } }
    let(:expected_cache_key) { Translation.where(locale: locale).order(updated_at: :desc).take.updated_at.to_s }

    before do
      graphql_execute(query, variables: variables)
    end

    context 'with a valid locale' do
      let(:locale) { 'de-de' }

      context 'without a correct cache_key' do
        let(:cache_key) { nil }

        it 'returns metadata' do
          expect(graphql_response['data']['translations']).to include({ 'isCacheStillValid' => false, 'cacheKey' => expected_cache_key })
        end

        it 'returns translations' do
          expect(graphql_response['data']['translations']['translations']).to include({ 'yes' => 'ja' })
        end

        it 'does not return empty or "untranslated" translations' do
          expect(graphql_response['data']['translations']['translations'].select { |k, v| v.empty? || k == v }).to be_empty
        end
      end

      context 'with the correct cache key' do
        let(:cache_key) { expected_cache_key }

        it 'returns only metadata' do
          expect(graphql_response['data']['translations']).to include({ 'isCacheStillValid' => true, 'cacheKey' => nil, 'translations' => nil })
        end
      end

    end

    context 'with an invalid locale' do
      let(:locale) { 'invalid-locale' }
      let(:cache_key) { nil }

      it 'returns error type' do
        expect(graphql_response['errors'][0]['extensions']).to include({ 'type' => 'RuntimeError' })
      end

      it 'returns error message' do
        expect(graphql_response['errors'][0]).to include('message' => "No translations found for locale #{locale}.")
      end
    end
  end

end
