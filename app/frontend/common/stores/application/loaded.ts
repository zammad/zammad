// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import useNotifications from '@common/composables/useNotifications'
import type { SingleValueStore } from '@common/types/store'
import testFlags from '@common/utils/testFlags'
import { defineStore } from 'pinia'

const useApplicationLoadedStore = defineStore('applicationLoaded', {
  state: (): SingleValueStore<boolean> => {
    return {
      value: false,
    }
  },
  getters: {
    loading(): boolean {
      return !this.value
    },
  },
  actions: {
    setLoaded(): void {
      const loadingAppElement: Maybe<HTMLElement> =
        document.getElementById('loading-app')

      if (useNotifications().hasErrors()) {
        loadingAppElement
          ?.getElementsByClassName('loading-failed')
          .item(0)
          ?.classList.add('active')
        return
      }

      this.value = true

      if (loadingAppElement) {
        loadingAppElement.remove()
      }

      testFlags.set('applicationLoaded.loaded')
    },
  },
})

export default useApplicationLoadedStore
