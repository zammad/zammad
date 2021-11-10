// Copyright (C) 2012-2021 Zammad Foundation, https://zammad-foundation.org/

import { defineStore } from 'pinia'
import { DefaultStore } from '@common/types/store'
import { useApplicationConfigQuery } from '@mobile/graphql/api'
import { QueryHandler } from '@common/server/apollo/handler'

// TODO: maybe we can avoid the usage of unknown?
const useApplicationConfigStore = defineStore('applicationConfig', {
  state: (): DefaultStore<Record<string, unknown>> => {
    return {
      value: {},
    }
  },
  getters: {
    get() {
      return (name: string): unknown => this.value[name]
    },
  },
  actions: {
    async getConfig(): Promise<void> {
      const configQuery = new QueryHandler(useApplicationConfigQuery)

      const result = await configQuery.loadedResult()

      if (result?.applicationConfig) {
        result.applicationConfig.forEach((item) => {
          this.value[item.key] = item.value
        })
      }
    },
  },
})

export default useApplicationConfigStore
