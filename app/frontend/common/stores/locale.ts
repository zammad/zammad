// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { defineStore } from 'pinia'
import log from '@common/utils/log'
import localeForBrowserLanguage from '@common/i18n/localeForBrowserLanguage'
import getAvailableLocales from '@common/i18n/availableLocales'
import useTranslationsStore from '@common/stores/translations'
import { LocalesQuery } from '@common/graphql/types'
import type { LastArrayElement } from 'type-fest'
import { ref } from 'vue'

type Locale = LastArrayElement<LocalesQuery['locales']>

const useLocaleStore = defineStore('locale', () => {
  const localeData = ref<Maybe<Locale>>(null)

  const updateLocale = async (newLocale?: string): Promise<void> => {
    const availableLocales = await getAvailableLocales()

    if (!availableLocales?.length) return

    let newLocaleData

    if (newLocale) {
      newLocaleData = availableLocales.find((elem) => {
        return elem.locale === newLocale
      })
    }

    if (!newLocaleData)
      newLocaleData = localeForBrowserLanguage(availableLocales || [])

    log.debug('localeStore.updateLocale()', newLocaleData)

    // Update the translation store, when the locale is different.
    if (localeData.value?.locale !== newLocaleData.locale) {
      await useTranslationsStore().load(newLocaleData.locale)
      localeData.value = newLocaleData

      document.documentElement.setAttribute('dir', newLocaleData.dir)
      document.documentElement.setAttribute('lang', newLocaleData.locale)
    }
  }

  return {
    localeData,
    updateLocale,
  }
})

export default useLocaleStore
