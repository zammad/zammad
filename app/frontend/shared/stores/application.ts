// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { computed, ref } from 'vue'
import { defineStore } from 'pinia'
import {
  useNotifications,
  NotificationTypes,
} from '@shared/components/CommonNotifications'
import type { ConfigList } from '@shared/types/store'
import log from '@shared/utils/log'
import type {
  ApplicationConfigQuery,
  ApplicationConfigQueryVariables,
} from '@shared/graphql/types'
import { useConfigUpdatesSubscription } from '@shared/graphql/subscriptions/configUpdates.api'
import { useApplicationConfigQuery } from '@shared/graphql/queries/applicationConfig.api'
import {
  QueryHandler,
  SubscriptionHandler,
} from '@shared/server/apollo/handler'
import testFlags from '@shared/utils/testFlags'

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

let connectionNotificationId: string

// TODO: consider switching from notification to a modal dialog, and improving the message
const notifications = useNotifications()

export const useApplicationStore = defineStore(
  'application',
  () => {
    const loaded = ref(false)
    const loading = computed(() => !loaded.value)

    const setLoaded = (): void => {
      const loadingAppElement: Maybe<HTMLElement> =
        document.getElementById('loading-app')

      if (notifications.hasErrors()) {
        loadingAppElement
          ?.getElementsByClassName('loading-failed')
          .item(0)
          ?.classList.add('active')
        return
      }

      loaded.value = true

      if (loadingAppElement) {
        loadingAppElement.remove()
      }

      testFlags.set('applicationLoaded.loaded')
    }

    const connected = ref(false)

    const bringConnectionUp = (): void => {
      if (connected.value) return

      log.debug('Application connection just came up.')

      if (connectionNotificationId) {
        notifications.removeNotification(connectionNotificationId)
      }
      connected.value = true
    }

    const takeConnectionDown = (): void => {
      if (!connected.value) return

      log.debug('Application connection just went down.')

      connectionNotificationId = notifications.notify({
        message: __('The connection to the server was lost.'),
        type: NotificationTypes.Error,
        persistent: true,
      })
      connected.value = false
    }

    const config = ref<ConfigList>({})

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

      const result = await configQuery.loadedResult(true)
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
      connected,
      bringConnectionUp,
      takeConnectionDown,
      config,
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
