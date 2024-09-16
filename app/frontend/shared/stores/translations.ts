// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { defineStore } from 'pinia'
import { effectScope, ref } from 'vue'

import { useTranslationsLazyQuery } from '#shared/graphql/queries/translations.api.ts'
import type {
  TranslationsQuery,
  TranslationsQueryVariables,
} from '#shared/graphql/types.ts'
import { i18n } from '#shared/i18n.ts'
import { QueryHandler } from '#shared/server/apollo/handler/index.ts'
import { useApplicationStore } from '#shared/stores/application.ts'
import log from '#shared/utils/log.ts'

interface TranslationsCacheValue {
  cacheKey: string
  translations: Record<string, string>
}

const localStorageKey = (locale: string): string => {
  return `translationsStoreCache::${locale}`
}

const loadCache = (locale: string): TranslationsCacheValue => {
  const cached = JSON.parse(
    window.localStorage.getItem(localStorageKey(locale)) || '{}',
  )
  log.debug('translations.loadCache()', locale, cached)
  return {
    cacheKey: cached.cacheKey || '',
    translations: cached.translations || {},
  }
}

const setCache = (locale: string, value: TranslationsCacheValue): void => {
  const serialized = JSON.stringify(value)
  window.localStorage.setItem(localStorageKey(locale), serialized)
  log.debug('translations.setCache()', locale, value)
}

let translationsQuery: QueryHandler<
  TranslationsQuery,
  TranslationsQueryVariables
>

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
    const cacheKey = ref<string>('CACHE_EMPTY')
    const translationData = ref<Record<string, string>>({})

    const load = async (locale: string): Promise<void> => {
      log.debug('translations.load()', locale)

      const cachedData = loadCache(locale)

      const translationsQuery = getTranslationsQuery()

      const { data: result } = await translationsQuery.query({
        variables: {
          cacheKey: cachedData.cacheKey,
          locale,
        },
      })

      if (!result?.translations) {
        return
      }

      if (result.translations.isCacheStillValid) {
        cacheKey.value = cachedData.cacheKey
        translationData.value = cachedData.translations
      } else {
        cacheKey.value = result.translations.cacheKey || 'CACHE_EMPTY'
        translationData.value = result.translations.translations

        setCache(locale, {
          cacheKey: cacheKey.value,
          translations: translationData.value,
        })
      }

      log.debug(
        'translations.load() setting new translation map',
        locale,
        translationData.value,
      )
      i18n.setTranslationMap(new Map(Object.entries(translationData.value)))
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
