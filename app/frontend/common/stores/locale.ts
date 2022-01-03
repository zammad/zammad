// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { defineStore } from 'pinia'
import type { SingleValueStore } from '@common/types/store'
import log from '@common/utils/log'
import localeForBrowserLanguage from '@common/utils/i18n/localeForBrowserLanguage'
import getAvailableLocales from '@common/utils/i18n/availableLocales'
import useTranslationsStore from '@common/stores/translations'

const useLocaleStore = defineStore('locale', {
  state: (): SingleValueStore<string> => {
    return {
      value: '',
    }
  },
  actions: {
    async updateLocale(newLocale?: string): Promise<void> {
      let locale = newLocale

      if (!locale) {
        const availableLocales = await getAvailableLocales()

        locale = availableLocales
          ? localeForBrowserLanguage(availableLocales)
          : 'en-us'
      }

      log.debug('localeStore.updateLocale()', locale)

      // Update the translation store, when the locale is different.
      if (this.value !== locale) {
        await useTranslationsStore().load(locale)
      }

      this.value = locale
    },
  },
})

export default useLocaleStore
