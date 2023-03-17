// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { reactive, ref } from 'vue'
import { defineStore } from 'pinia'
import { i18n } from '@shared/i18n'
import log from '@shared/utils/log'
import { useTranslationsQuery } from '@shared/graphql/queries/translations.api'
import { QueryHandler } from '@shared/server/apollo/handler'
import type {
  TranslationsQuery,
  TranslationsQueryVariables,
} from '@shared/graphql/types'
import type { ReactiveFunction } from '@shared/types/utils'
import { useApplicationStore } from '@shared/stores/application'

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

const translationsQueryVariables = reactive({})

let translationsQuery: QueryHandler<
  TranslationsQuery,
  TranslationsQueryVariables
>

const getTranslationsQuery = () => {
  if (translationsQuery) return translationsQuery

  translationsQuery = new QueryHandler(
    useTranslationsQuery(
      translationsQueryVariables as ReactiveFunction<TranslationsQueryVariables>,
    ),
    {
      // Don't show an error while app is loading as this would cause startup failure.
      errorShowNotification: useApplicationStore().loaded,
    },
  )

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

      Object.assign(translationsQueryVariables, {
        cacheKey: cachedData.cacheKey,
        locale,
      })

      const query = getTranslationsQuery()

      const result = await query.loadedResult()
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
