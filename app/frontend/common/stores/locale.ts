// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { defineStore } from 'pinia'
import type { SingleValueStore } from '@common/types/store'
import log from '@common/utils/log'
import localeForBrowserLanguage from '@common/utils/i18n/localeForBrowserLanguage'
import getAvailableLocales from '@common/utils/i18n/availableLocales'
import useTranslationsStore from '@common/stores/translations'
import { LocalesQuery } from '@common/graphql/types'
import type { LastArrayElement } from 'type-fest'

type Locale = LastArrayElement<LocalesQuery['locales']>

const useLocaleStore = defineStore('locale', {
  state: (): SingleValueStore<Maybe<Locale>> => {
    return {
      value: null,
    }
  },
  actions: {
    async updateLocale(newLocale?: string): Promise<void> {
      const availableLocales = await getAvailableLocales()

      if (!availableLocales?.length) return

      let locale

      if (newLocale) {
        locale = availableLocales.find((elem) => {
          return elem.locale === newLocale
        })
      }

      if (!locale) locale = localeForBrowserLanguage(availableLocales || [])

      log.debug('localeStore.updateLocale()', locale)

      // Update the translation store, when the locale is different.
      if (this.value?.locale !== locale.locale) {
        await useTranslationsStore().load(locale.locale)
        this.value = locale

        document.documentElement.setAttribute('dir', locale.dir)
        document.documentElement.setAttribute('lang', locale.locale)
      }
    },
  },
})

export default useLocaleStore
