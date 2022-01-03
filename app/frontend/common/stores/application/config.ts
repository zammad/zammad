// Copyright (C) 2012-2021 Zammad Foundation, https://zammad-foundation.org/

import { defineStore } from 'pinia'
import type { SingleValueStore, ConfigValues } from '@common/types/store'
import type {
  ApplicationConfigQuery,
  ApplicationConfigQueryVariables,
} from '@common/graphql/types'
import {
  useApplicationConfigQuery,
  useConfigUpdatedSubscription,
} from '@mobile/graphql/api'
import {
  QueryHandler,
  SubscriptionHandler,
} from '@common/server/apollo/handler'

let configUpdatedSubscriptionInitialized = false

let applicationConfigQuery: QueryHandler<
  ApplicationConfigQuery,
  ApplicationConfigQueryVariables
>

const getApplicationConfigQuery = () => {
  if (applicationConfigQuery) return applicationConfigQuery

  applicationConfigQuery = new QueryHandler(
    useApplicationConfigQuery({ fetchPolicy: 'no-cache' }),
  )

  return applicationConfigQuery
}

const useApplicationConfigStore = defineStore('applicationConfig', {
  state: (): SingleValueStore<Record<string, ConfigValues>> => {
    return {
      value: {},
    }
  },
  getters: {
    get() {
      return <T extends ConfigValues = ConfigValues>(name: string): T =>
        this.value[name] as T
    },
  },
  actions: {
    async getConfig(): Promise<void> {
      const configQuery = getApplicationConfigQuery()

      const result = await configQuery.loadedResult(true)
      if (result?.applicationConfig) {
        result.applicationConfig.forEach((item) => {
          this.value[item.key] = item.value
        })
      }

      if (!configUpdatedSubscriptionInitialized) {
        const configUpdatedSubscription = new SubscriptionHandler(
          useConfigUpdatedSubscription(),
        )

        configUpdatedSubscription.onResult((result) => {
          const updatedSetting = result.data?.configUpdated.setting

          if (updatedSetting) {
            this.value[updatedSetting.key] = updatedSetting.value
          }
        })

        configUpdatedSubscriptionInitialized = true
      }
    },

    async resetAndGetConfig(): Promise<void> {
      this.$reset()

      await this.getConfig()
    },
  },
})

export default useApplicationConfigStore
