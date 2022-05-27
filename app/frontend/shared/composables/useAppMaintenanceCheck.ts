// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { onMounted, reactive, watch } from 'vue'
import { useRouteQuery } from '@vueuse/router'
import {
  useNotifications,
  NotificationTypes,
} from '@shared/components/CommonNotifications'
import { useApplicationBuildChecksumQuery } from '@shared/graphql/queries/applicationBuildChecksum.api'
import { useAppMaintenanceSubscription } from '@shared/graphql/subscriptions/appMaintenance.api'
import {
  ApplicationBuildChecksumQuery,
  ApplicationBuildChecksumQueryVariables,
  AppMaintenanceType,
  AppMaintenanceSubscription,
  AppMaintenanceSubscriptionVariables,
} from '@shared/graphql/types'
import {
  QueryHandler,
  SubscriptionHandler,
} from '@shared/server/apollo/handler'
import testFlags from '@shared/utils/testFlags'

let query: QueryHandler<
  ApplicationBuildChecksumQuery,
  ApplicationBuildChecksumQueryVariables
>
let previousChecksum: string
let subscription: SubscriptionHandler<
  AppMaintenanceSubscription,
  AppMaintenanceSubscriptionVariables
>

const useAppMaintenanceCheck = () => {
  const notify = (message: string) => {
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
        testFlags.set('useApplicationBuildChecksumQuery.firstResult')
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

export default useAppMaintenanceCheck
