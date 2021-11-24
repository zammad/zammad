// Copyright (C) 2012-2021 Zammad Foundation, https://zammad-foundation.org/

import { defineStore } from 'pinia'
import { SingleValueStore } from '@common/types/store'
import log from '@common/utils/log'
import localeForBrowserLanguage from '@common/utils/i18n/localeForBrowserLanguage'
import { QueryHandler } from '@common/server/apollo/handler'
import { useLocalesQuery } from '@common/graphql/api'
import useSessionUserStore from '@common/stores/session/user'

const useLocaleStore = defineStore('locale', {
  state: (): SingleValueStore<string> => {
    return {
      value: '',
    }
  },
  actions: {
    async updateLocale() {
      let locale = ''
      if (useSessionUserStore().value) {
        locale = useSessionUserStore().value?.preferences?.locale
      }
      if (!locale) {
        const query = new QueryHandler(useLocalesQuery())
        const availableLocales =
          query.result().value ?? (await query.loadedResult())
        locale = availableLocales
          ? localeForBrowserLanguage(availableLocales?.locales)
          : 'en-us'
      }
      log.debug('localeStore.updateLocale()', locale)
      this.value = locale
    },
  },
})

export default useLocaleStore
