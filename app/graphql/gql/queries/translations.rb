# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class Translations < BaseQueryWithPayload

    description 'Translations for a given locale'

    argument :locale,    String, description: 'The locale to fetch translations for, e.g. "de-de".'
    argument :cache_key, String, required:    false,
                                 description: 'Cache identifier that the front end used to store the translations when fetching last time. If this is still up-to-date, no data will be returned and the front end should use its cached data.'

    field :is_cache_still_valid, Boolean, null: false, description: "If this is true, then the front end's translation cache is still valid and should be used, cacheKey and translation will not be returned."
    field :cache_key, String, description: 'Cache key that the front end should use to cache the new translation data.'
    field :translations, GraphQL::Types::JSON, description: 'The actual translation data as Hash where keys are source and values target strings (excluding untranslated strings).'

    def self.authorize(...)
      true # This query should be available for all (including unauthenticated) users.
    end

    def resolve(locale:, cache_key: nil)

      base_query = Translation.where(locale: locale).where('target != source').where.not(target: '')
      new_cache_key = base_query.order(updated_at: :desc).take&.updated_at.to_s

      if new_cache_key.empty?
        raise ActiveRecord::RecordNotFound, "No translations found for locale #{locale}."
      end

      if new_cache_key == cache_key
        return { is_cache_still_valid: true }
      end

      {
        is_cache_still_valid: false,
        cache_key:            new_cache_key,
        translations:         base_query.all.pluck(:source, :target).to_h
      }
    end

  end
end
