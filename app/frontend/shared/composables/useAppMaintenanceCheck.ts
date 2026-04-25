// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { useRouteQuery } from '@vueuse/router'
import { computed, onMounted } from 'vue'

import {
  useNotifications,
  NotificationTypes,
} from '#shared/components/CommonNotifications/index.ts'
import type { Notification } from '#shared/components/CommonNotifications/types.ts'
import { useApplicationBuildChecksumQuery } from '#shared/graphql/queries/applicationBuildChecksum.api.ts'
import { useAppMaintenanceSubscription } from '#shared/graphql/subscriptions/appMaintenance.api.ts'
import type {
  ApplicationBuildChecksumQuery,
  ApplicationBuildChecksumQueryVariables,
  AppMaintenanceSubscription,
  AppMaintenanceSubscriptionVariables,
} from '#shared/graphql/types.ts'
import { EnumAppMaintenanceType } from '#shared/graphql/types.ts'
import { QueryHandler, SubscriptionHandler } from '#shared/server/apollo/handler/index.ts'
import testFlags from '#shared/utils/testFlags.ts'

import { useQueryPolling } from './useQueryPolling.ts'

let checksumQuery: QueryHandler<
  ApplicationBuildChecksumQuery,
  ApplicationBuildChecksumQueryVariables
>
let previousChecksum: string
let appMaintenanceSubscription: SubscriptionHandler<
  AppMaintenanceSubscription,
  AppMaintenanceSubscriptionVariables
>

interface UseAppMaintenanceCheckOptions {
  onNeedRefresh?: () => void
}

const useAppMaintenanceCheck = (maintenanceOptions: UseAppMaintenanceCheckOptions = {}) => {
  const notify = (
    notification: Pick<
      Notification,
      'message' | 'closeCallback' | 'actionLabel' | 'actionCallback'
    >,
  ) => {
    useNotifications().notify({
      id: 'app-maintenance',
      type: NotificationTypes.Warn,
      persistent: true,
      ...notification,
    })
  }

  onMounted(() => {
    if (checksumQuery) return

    // Default poll interval: every minute.
    const defaultPollInterval = 60 * 1000

    const applicationRebuildCheckInterval = useRouteQuery(
      'ApplicationRebuildCheckInterval',
      defaultPollInterval.toString(),
    )

    const pollInterval = computed(() => {
      return parseInt(applicationRebuildCheckInterval.value, 10)
    })

    checksumQuery = new QueryHandler(useApplicationBuildChecksumQuery(), {
      errorShowNotification: false,
    })

    const { startPolling } = useQueryPolling(checksumQuery, pollInterval)

    checksumQuery.watchOnceOnResult(() => {
      startPolling()
    })

    const notificationMessage = __(
      'A newer version of the app is available. Please reload at your earliest.',
    )

    checksumQuery.watchOnResult((queryResult): void => {
      if (!queryResult?.applicationBuildChecksum.length) return

      if (!previousChecksum) {
        previousChecksum = queryResult?.applicationBuildChecksum
        testFlags.set('useApplicationBuildChecksumQuery.firstResult')
      }

      if (queryResult?.applicationBuildChecksum === previousChecksum) return

      notify({
        message: notificationMessage,
        closeCallback: maintenanceOptions.onNeedRefresh,
        actionLabel: __('Reload now'),
        actionCallback: () => {
          maintenanceOptions.onNeedRefresh?.()
          window.location.reload()
        },
      })
    })

    appMaintenanceSubscription = new SubscriptionHandler(useAppMaintenanceSubscription())
    appMaintenanceSubscription.onResult((result) => {
      const type = result.data?.appMaintenance?.type

      let message = notificationMessage

      if (!type) {
        testFlags.set('useAppMaintenanceSubscription.subscribed')
        return
      }

      switch (type) {
        case EnumAppMaintenanceType.ConfigChanged:
          message = __('The configuration of Zammad has changed. Please reload at your earliest.')
          break
        case EnumAppMaintenanceType.RestartAuto:
        case EnumAppMaintenanceType.RestartManual:
          // TODO: this case cannot be handled right now. Legacy interface performs a connectivity check.
          break
        default:
          break
      }

      notify({
        message,
        actionLabel: __('Reload now'),
        actionCallback: () => window.location.reload(),
      })
    })
  })
}

export default useAppMaintenanceCheck
