// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { defineStore } from 'pinia'
import { effectScope, ref } from 'vue'

import { useTranslationsLazyQuery } from '#shared/graphql/queries/translations.api.ts'
import type { TranslationsQuery, TranslationsQueryVariables } from '#shared/graphql/types.ts'
import { i18n } from '#shared/i18n.ts'
import { QueryHandler } from '#shared/server/apollo/handler/index.ts'
import { useApplicationStore } from '#shared/stores/application.ts'
import log from '#shared/utils/log.ts'

interface TranslationsCacheValue {
  cacheKey: string
  translations: Record<string, string>
  locale: string
}

export const LOCAL_STORAGE_KEY = 'translationsStoreCache'

const CACHE_KEY_EMPTY_NAME = 'CACHE_EMPTY'

const loadCache = (locale: string): TranslationsCacheValue => {
  const cached = JSON.parse(window.localStorage.getItem(LOCAL_STORAGE_KEY) || '{}')

  log.debug('translations.loadCache()', locale, cached)

  return {
    cacheKey: cached.cacheKey || '',
    translations: cached.translations || {},
    locale: cached.locale || '',
  }
}

const setCache = (locale: string, value: TranslationsCacheValue): void => {
  const serialized = JSON.stringify(value)

  window.localStorage.setItem(LOCAL_STORAGE_KEY, serialized)

  log.debug('translations.setCache()', locale, value)
}

let translationsQuery: QueryHandler<TranslationsQuery, TranslationsQueryVariables>

const getTranslationsQuery = () => {
  if (translationsQuery) return translationsQuery

  const scope = effectScope()

  scope.run(() => {
    translationsQuery = new QueryHandler(
      useTranslationsLazyQuery({} as TranslationsQueryVariables),
      {
        // Don't show an error while app is loading as this would cause startup failure.
        errorShowNotification: useApplicationStore().loaded,
      },
    )
  })

  return translationsQuery
}

export const useTranslationsStore = defineStore(
  'translations',
  () => {
    const cacheKey = ref<string>(CACHE_KEY_EMPTY_NAME)
    const translationData = ref<Record<string, string>>({})

    const load = async (newLocale: string): Promise<void> => {
      log.debug('translations.load()', newLocale)

      const cachedData = loadCache(newLocale)

      // Always start with the cache key we already have for the requested locale so the
      // backend can decide if the cache is still valid and omit the payload if possible.
      cacheKey.value = cachedData.cacheKey || CACHE_KEY_EMPTY_NAME

      const translationsQuery = getTranslationsQuery()

      const { data: result } = await translationsQuery.query({
        variables: {
          cacheKey: cacheKey.value,
          locale: newLocale,
        },
      })

      if (!result?.translations) return

      const isCacheValid = result.translations.isCacheStillValid && cachedData.locale === newLocale

      cacheKey.value = isCacheValid
        ? cachedData.cacheKey || cacheKey.value
        : result.translations.cacheKey || CACHE_KEY_EMPTY_NAME

      translationData.value = isCacheValid
        ? cachedData.translations
        : result.translations.translations || {}

      if (!isCacheValid) {
        setCache(newLocale, {
          cacheKey: cacheKey.value,
          translations: translationData.value,
          locale: newLocale,
        })
      }

      i18n.setTranslationMap(new Map(Object.entries(translationData.value || {})))

      log.debug('translations.load() setting new translation map', newLocale, translationData.value)
    }

    return {
      cacheKey,
      translationData,
      load,
    }
  },
  {
    requiresAuth: false,
  },
)
