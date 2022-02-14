// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import useNotifications from '@common/composables/useNotifications'
import {
  useApplicationBuildChecksumQuery,
  useAppMaintenanceSubscription,
} from '@common/graphql/api'
import {
  ApplicationBuildChecksumQuery,
  ApplicationBuildChecksumQueryVariables,
  AppMaintenanceType,
  AppMaintenanceSubscription,
  AppMaintenanceSubscriptionVariables,
} from '@common/graphql/types'
import {
  QueryHandler,
  SubscriptionHandler,
} from '@common/server/apollo/handler'
import { NotificationTypes } from '@common/types/notification'
import { onMounted, reactive, watch } from 'vue'
import { useRouteQuery } from '@vueuse/router'
import testFlags from '@common/utils/testFlags'

let query: QueryHandler<
  ApplicationBuildChecksumQuery,
  ApplicationBuildChecksumQueryVariables
>
let previousChecksum: string
let subscription: SubscriptionHandler<
  AppMaintenanceSubscription,
  AppMaintenanceSubscriptionVariables
>

export default function useAppMaintenanceCheck() {
  function notify(message: string) {
    useNotifications().notify({
      message,
      type: NotificationTypes.WARN,
      persistent: true,
      callback: () => {
        window.location.reload()
      },
    })
  }

  onMounted(() => {
    if (query) return

    // Default poll interval: every minute.
    const defaultPollInterval = 60 * 1000

    const applicationRebuildCheckInterval = useRouteQuery(
      'ApplicationRebuildCheckInterval',
      defaultPollInterval.toString(),
    )

    const options = reactive({
      pollInterval: parseInt(applicationRebuildCheckInterval.value, 10),
    })

    watch(applicationRebuildCheckInterval, () => {
      options.pollInterval = parseInt(applicationRebuildCheckInterval.value, 10)
    })

    query = new QueryHandler(useApplicationBuildChecksumQuery(options))

    let notificationMessage = __(
      'A newer version of the app is available. Please reload at your earliest.',
    )

    query.watchOnResult((queryResult): void => {
      if (!queryResult?.applicationBuildChecksum.length) return
      if (!previousChecksum) {
        previousChecksum = queryResult?.applicationBuildChecksum
      }
      if (queryResult?.applicationBuildChecksum !== previousChecksum) {
        notify(notificationMessage)
      }
    })

    subscription = new SubscriptionHandler(useAppMaintenanceSubscription())
    subscription.onResult((result) => {
      const type = result.data?.appMaintenance.type
      if (!type) {
        testFlags.set('useAppMaintenanceSubscription.subscribed')
        return
      }
      switch (type) {
        case AppMaintenanceType.ConfigChanged:
          notificationMessage = __(
            'The configuration of Zammad has changed. Please reload at your earliest.',
          )
          break
        case AppMaintenanceType.RestartAuto:
        case AppMaintenanceType.RestartManual:
          // TODO: this case cannot be handled right now. Legacy interface performs a connectivity check.
          break
        default:
          break
      }
      notify(notificationMessage)
    })
  })
}
