// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { ref } from 'vue'
import { defineStore } from 'pinia'
import type { LastArrayElement } from 'type-fest'
import log from '@shared/utils/log'
import localeForBrowserLanguage from '@shared/i18n/localeForBrowserLanguage'
import getAvailableLocales from '@shared/i18n/availableLocales'
import type { LocalesQuery } from '@shared/graphql/types'
import { useTranslationsStore } from './translations'

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
