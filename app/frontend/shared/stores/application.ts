// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { computed, ref, type Ref } from 'vue'
import { defineStore } from 'pinia'
import { useNotifications } from '#shared/components/CommonNotifications/index.ts'
import type { ConfigList } from '#shared/types/store.ts'
import type {
  ApplicationConfigQuery,
  ApplicationConfigQueryVariables,
} from '#shared/graphql/types.ts'
import { useConfigUpdatesSubscription } from '#shared/graphql/subscriptions/configUpdates.api.ts'
import { useApplicationConfigQuery } from '#shared/graphql/queries/applicationConfig.api.ts'
import {
  QueryHandler,
  SubscriptionHandler,
} from '#shared/server/apollo/handler/index.ts'
import testFlags from '#shared/utils/testFlags.ts'
import { useApplicationLoaded } from '#shared/composables/useApplicationLoaded.ts'

let configUpdatesSubscriptionInitialized = false

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

// TODO: consider switching from notification to a modal dialog, and improving the message
const notifications = useNotifications()
const { loaded } = useApplicationLoaded()

export const useApplicationStore = defineStore(
  'application',
  () => {
    const loading = computed(() => !loaded.value)

    const setLoaded = (): void => {
      const loadingAppElement: Maybe<HTMLElement> =
        document.getElementById('loading-app')

      if (notifications.hasErrors()) {
        loadingAppElement
          ?.getElementsByClassName('loading-animation')
          .item(0)
          ?.classList.add('error')

        loadingAppElement
          ?.getElementsByClassName('loading-sr-text')
          .item(0)
          ?.setAttribute('aria-hidden', 'true')

        const loadingFailedElement = loadingAppElement
          ?.getElementsByClassName('loading-failed')
          .item(0)

        loadingFailedElement?.classList.add('active')
        loadingFailedElement?.setAttribute('aria-hidden', 'false')

        return
      }

      loaded.value = true

      if (loadingAppElement) {
        loadingAppElement.remove()
      }

      testFlags.set('applicationLoaded.loaded')
    }

    const config = ref<Record<string, unknown>>({})

    const initializeConfigUpdateSubscription = (): void => {
      const configUpdatesSubscription = new SubscriptionHandler(
        useConfigUpdatesSubscription(),
      )

      configUpdatesSubscription.onResult((result) => {
        const updatedSetting = result.data?.configUpdates.setting
        if (updatedSetting) {
          config.value[updatedSetting.key] = updatedSetting.value
        } else {
          testFlags.set('useConfigUpdatesSubscription.subscribed')
        }
      })

      configUpdatesSubscriptionInitialized = true
    }

    const getConfig = async (): Promise<void> => {
      const configQuery = getApplicationConfigQuery()

      const { data: result } = await configQuery.refetch()
      if (result?.applicationConfig) {
        result.applicationConfig.forEach((item) => {
          config.value[item.key] = item.value
        })

        // app/assets/javascripts/app/config.coffee
        config.value.api_path = '/api/v1'
      }

      if (!configUpdatesSubscriptionInitialized) {
        initializeConfigUpdateSubscription()
      }
    }

    const resetAndGetConfig = async (): Promise<void> => {
      config.value = {}

      await getConfig()
    }

    const hasCustomProductBranding = computed(() =>
      Boolean(
        config.value.product_logo && config.value.product_logo !== 'logo.svg',
      ),
    )

    return {
      loaded,
      loading,
      setLoaded,
      config: config as unknown as Ref<ConfigList>,
      initializeConfigUpdateSubscription,
      getConfig,
      resetAndGetConfig,
      hasCustomProductBranding,
    }
  },
  {
    requiresAuth: false,
  },
)
