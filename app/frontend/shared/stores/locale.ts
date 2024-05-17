// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { defineStore } from 'pinia'
import { ref } from 'vue'

import type { LocalesQuery } from '#shared/graphql/types.ts'
import getAvailableLocales from '#shared/i18n/availableLocales.ts'
import localeForBrowserLanguage from '#shared/i18n/localeForBrowserLanguage.ts'
import log from '#shared/utils/log.ts'

import { useTranslationsStore } from './translations.ts'

import type { LastArrayElement } from 'type-fest'

type Locale = LastArrayElement<LocalesQuery['locales']>

export const useLocaleStore = defineStore(
  'locale',
  () => {
    const localeData = ref<Maybe<Locale>>(null)
    const locales = ref<Maybe<LocalesQuery['locales']>>(null)

    const loadLocales = async (): Promise<void> => {
      if (locales.value) return

      locales.value = await getAvailableLocales()
    }

    const setLocale = async (locale?: string): Promise<void> => {
      await loadLocales()

      let newLocaleData

      if (locale) {
        newLocaleData = locales.value?.find((elem) => {
          return elem.locale === locale
        })
      }

      if (!newLocaleData)
        newLocaleData = localeForBrowserLanguage(locales.value || [])

      log.debug('localeStore.setLocale()', newLocaleData)

      // Update the translation store, when the locale is different.
      if (localeData.value?.locale !== newLocaleData.locale) {
        await useTranslationsStore().load(newLocaleData.locale)
        localeData.value = newLocaleData

        document.documentElement.setAttribute('dir', newLocaleData.dir)
        document.documentElement.setAttribute('lang', newLocaleData.locale)
      }
    }

    return {
      locales,
      localeData,
      setLocale,
      loadLocales,
    }
  },
  {
    requiresAuth: false,
  },
)
