// Copyright (C) 2012-2021 Zammad Foundation, https://zammad-foundation.org/

import { defineStore } from 'pinia'
import { SingleValueStore, ConfigValues } from '@common/types/store'
import { useApplicationConfigQuery } from '@mobile/graphql/api'
import { QueryHandler } from '@common/server/apollo/handler'

// TODO: maybe we can avoid the usage of unknown?
const useApplicationConfigStore = defineStore('applicationConfig', {
  state: (): SingleValueStore<Record<string, ConfigValues>> => {
    return {
      value: {},
    }
  },
  getters: {
    get() {
      return (name: string): ConfigValues => this.value[name]
    },
  },
  actions: {
    async getConfig(refetchQuery = false): Promise<void> {
      const configQuery = new QueryHandler(useApplicationConfigQuery())

      // Trigger query refetch in some situtations, to skip the cache.
      if (refetchQuery) {
        configQuery.refetch()
      }

      const result = await configQuery.loadedResult()

      if (result?.applicationConfig) {
        result.applicationConfig.forEach((item) => {
          this.value[item.key] = item.value
        })
      }
    },

    async resetAndGetConfig(): Promise<void> {
      this.$reset()

      await this.getConfig(true)
    },
  },
})

export default useApplicationConfigStore
