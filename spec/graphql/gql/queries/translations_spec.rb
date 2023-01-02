# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::Translations, type: :graphql do

  context 'when fetching translations' do
    let(:query) do
      <<~QUERY
        query translations($locale: String!, $cacheKey: String)  {
          translations(locale: $locale, cacheKey: $cacheKey) {
            isCacheStillValid
            cacheKey
            translations
          }
        }
      QUERY
    end
    let(:variables)          { { locale: locale, cacheKey: cache_key } }
    let(:expected_cache_key) { Translation.where(locale: locale).order(updated_at: :desc).take.updated_at.to_s }

    before do
      gql.execute(query, variables: variables)
    end

    context 'with a valid locale' do
      let(:locale) { 'de-de' }

      context 'without a correct cache_key' do
        let(:cache_key) { nil }

        it 'returns metadata' do
          expect(gql.result.data).to include({ 'isCacheStillValid' => false, 'cacheKey' => expected_cache_key })
        end

        it 'returns translations' do
          expect(gql.result.data['translations']).to include({ 'yes' => 'ja' })
        end

        it 'does not return empty or "untranslated" translations' do
          expect(gql.result.data['translations'].select { |k, v| v.empty? || k == v }).to be_empty
        end
      end

      context 'with the correct cache key' do
        let(:cache_key) { expected_cache_key }

        it 'returns only metadata' do
          expect(gql.result.data).to include({ 'isCacheStillValid' => true, 'cacheKey' => nil, 'translations' => nil })
        end
      end

    end

    context 'with an invalid locale' do
      let(:locale)    { 'invalid-locale' }
      let(:cache_key) { nil }

      it 'returns error type' do
        expect(gql.result.error_type).to eq(ActiveRecord::RecordNotFound)
      end

      it 'returns error message' do
        expect(gql.result.error_message).to eq("No translations found for locale #{locale}.")
      end
    end
  end

end
