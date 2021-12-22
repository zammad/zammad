// Copyright (C) 2012-2021 Zammad Foundation, https://zammad-foundation.org/

import { defineStore } from 'pinia'
import type {
  SingleValueStore,
  TranslationsStoreValue,
} from '@common/types/store'
import { i18n } from '@common/utils/i18n'
import log from '@common/utils/log'
import { useTranslationsQuery } from '@common/graphql/api'
import { QueryHandler } from '@common/server/apollo/handler'
import type {
  TranslationsQuery,
  TranslationsQueryVariables,
} from '@common/graphql/types'
import { reactive } from 'vue'
import type { ReactiveFunction } from '@common/types/utils'

function localStorageKey(locale: string): string {
  return `translationsStoreCache::${locale}`
}

function loadCache(locale: string): TranslationsStoreValue {
  const cached = JSON.parse(
    window.localStorage.getItem(localStorageKey(locale)) || '{}',
  )
  log.debug('translations.loadCache()', locale, cached)
  return {
    cacheKey: cached.cacheKey || '',
    translations: cached.translations || {},
  }
}

function setCache(locale: string, value: TranslationsStoreValue): void {
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
  )

  return translationsQuery
}

const useTranslationsStore = defineStore('translations', {
  state: (): SingleValueStore<TranslationsStoreValue> => {
    return {
      value: {
        cacheKey: 'CACHE_EMPTY',
        translations: {},
      },
    }
  },
  actions: {
    async load(locale: string): Promise<void> {
      log.debug('translations.load()', locale)

      const cachedData = loadCache(locale)

      Object.assign(translationsQueryVariables, {
        cacheKey: cachedData.cacheKey,
        locale,
      })

      const query = getTranslationsQuery()

      const result = await query.loadedResult()
      if (result?.translations?.isCacheStillValid) {
        this.value = cachedData
      } else {
        this.value = {
          cacheKey: result?.translations?.cacheKey || 'CACHE_EMPTY',
          translations: result?.translations?.translations,
        }
        setCache(locale, this.value)
      }

      log.debug(
        'translations.load() setting new translation map',
        locale,
        this.value.translations,
      )
      i18n.setTranslationMap(new Map(Object.entries(this.value.translations)))
    },
  },
})

export default useTranslationsStore
