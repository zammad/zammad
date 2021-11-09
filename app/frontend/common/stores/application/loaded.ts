import { DefaultStore } from '@common/types/store'
import { defineStore } from 'pinia'

const useApplicationLoadedStore = defineStore('applicationLoaded', {
  state: (): DefaultStore<boolean> => {
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
      this.value = true

      const loadingAppElement: Maybe<HTMLElement> =
        document.querySelector('#loadingApp')
      if (loadingAppElement) {
        loadingAppElement.remove()
      }
    },
  },
})

export default useApplicationLoadedStore
