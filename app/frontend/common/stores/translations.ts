// Copyright (C) 2012-2021 Zammad Foundation, https://zammad-foundation.org/

import { defineStore } from 'pinia'
import { SingleValueStore } from '@common/types/store'
import { i18n } from '@common/utils/i18n'
import log from '@common/utils/log'
import { useTranslationsQuery } from '@common/graphql/api'
import { QueryHandler } from '@common/server/apollo/handler'

type TranslationsStoreValue = { cacheKey: string; translations: object }

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

      const query = new QueryHandler(
        useTranslationsQuery({ locale, cacheKey: cachedData.cacheKey }),
      )

      const result = query.result().value ?? (await query.loadedResult())
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

      // TODO: trigger rerender?
    },
  },
})

export default useTranslationsStore
