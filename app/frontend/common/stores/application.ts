// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { defineStore } from 'pinia'
import useNotifications from '@common/composables/useNotifications'
import { NotificationTypes } from '@common/types/notification'
import type { ConfigList } from '@common/types/store'
import log from '@common/utils/log'
import type {
  ApplicationConfigQuery,
  ApplicationConfigQueryVariables,
} from '@common/graphql/types'
import {
  useApplicationConfigQuery,
  useConfigUpdatesSubscription,
} from '@common/graphql/api'
import {
  QueryHandler,
  SubscriptionHandler,
} from '@common/server/apollo/handler'
import testFlags from '@common/utils/testFlags'
import { computed, ref } from 'vue'

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

const useApplicationLoadedStore = defineStore('applicationLoaded', () => {
  const loaded = ref(false)
  const loading = computed(() => !loaded.value)

  const setLoaded = (): void => {
    const loadingAppElement: Maybe<HTMLElement> =
      document.getElementById('loading-app')

    if (useNotifications().hasErrors()) {
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
      type: NotificationTypes.ERROR,
      persistent: true,
    })
    connected.value = false
  }

  const config = ref<ConfigList>({})

  const getConfig = async (): Promise<void> => {
    const configQuery = getApplicationConfigQuery()

    const result = await configQuery.loadedResult(true)
    if (result?.applicationConfig) {
      result.applicationConfig.forEach((item) => {
        config.value[item.key] = item.value
      })
    }

    if (!configUpdatesSubscriptionInitialized) {
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
  }

  const resetAndGetConfig = async (): Promise<void> => {
    config.value = {}

    await getConfig()
  }

  return {
    loaded,
    loading,
    setLoaded,
    connected,
    bringConnectionUp,
    takeConnectionDown,
    config,
    getConfig,
    resetAndGetConfig,
  }
})

export default useApplicationLoadedStore
