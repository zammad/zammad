// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { acceptHMRUpdate, defineStore } from 'pinia'
import { computed, ref, shallowRef } from 'vue'

import {
  NotificationTypes,
  useNotifications,
} from '#shared/components/CommonNotifications/index.ts'
import { EnumBulkUpdateStatusStatus, type TicketBulkUpdateStatus } from '#shared/graphql/types.ts'
import SubscriptionHandler from '#shared/server/apollo/handler/SubscriptionHandler.ts'
import { useSessionStore } from '#shared/stores/session.ts'

import type { DragAndDropBulkEntityType } from '#desktop/components/Ticket/DragAndDropBulk/types.ts'
import { useUserCurrentTicketBulkUpdateStatusUpdatesSubscription } from '#desktop/entities/ticket/graphql/subscriptions/ticketBulkUpdateStatusUpdates.api.ts'

/**
 * Aligns with the default value for the async bulk jobs
 * ENV.fetch('ZAMMAD_UI_BULK_BACKGROUND_UPDATE_THRESHOLD', 20)
 */
export const BULK_CONFIRMATION_THRESHOLD = 20

// Manages the state of the currently running (or recently completed) ticket bulk update operation.
export const useTicketBulkUpdateStore = defineStore('ticketBulkUpdate', () => {
  const persistedState = ref<TicketBulkUpdateStatus | null>(null)

  const { userId, hasPermission } = useSessionStore()

  const runningNotificationDismissed = ref(false)

  const runningNotificationId = `ticket-bulk-update-running-${userId}`

  const { notify } = useNotifications()

  const status = computed(() => persistedState.value?.status ?? null)

  const isRunning = computed(
    () =>
      status.value === EnumBulkUpdateStatusStatus.Pending ||
      status.value === EnumBulkUpdateStatusStatus.Running,
  )

  const clearDismissedNotification = () => {
    runningNotificationDismissed.value = false
  }

  const clearBulkUpdateState = () => {
    persistedState.value = null
    clearDismissedNotification()
  }

  const showRunningNotification = () => {
    if (!persistedState.value) return
    if (runningNotificationDismissed.value) return

    notify({
      id: runningNotificationId,
      type: NotificationTypes.Info,
      message: __('Bulk action in progress…'),
      persistent: true,
      currentProgress: persistedState.value?.processedCount ?? undefined,
      maxProgress: persistedState.value?.total ?? undefined,
      closeCallback: () => {
        runningNotificationDismissed.value = true
      },
    })
  }

  const showCompletionNotifications = () => {
    if (!persistedState.value) return

    const total = persistedState.value.total ?? 0
    const failedCount = persistedState.value.failedCount ?? 0

    const successfulMessage = __('Bulk action successful for %s ticket(s).')

    const failedMessage = __(
      'Bulk action failed for %s ticket(s). Check attribute values and try again.',
    )

    const successfulMessagePlaceholder = [(total - failedCount).toString()]
    const failedMessagePlaceholder = [failedCount.toString()]

    if (total - failedCount > 0) {
      notify({
        id: runningNotificationId, // replace possible running notification
        type: NotificationTypes.Success,
        message: successfulMessage,
        messagePlaceholder: successfulMessagePlaceholder,
        durationMS: failedCount ? 5000 : undefined,
      })

      if (failedCount) {
        notify({
          id: `ticket-bulk-update-${EnumBulkUpdateStatusStatus.Failed}`, // additional notification for failed count
          type: NotificationTypes.Error,
          message: failedMessage,
          messagePlaceholder: failedMessagePlaceholder,
          durationMS: 5000,
        })
      }
    } else {
      notify({
        id: runningNotificationId, // replace possible running notification
        type: NotificationTypes.Error,
        message: failedMessage,
        messagePlaceholder: failedMessagePlaceholder,
        durationMS: 5000,
      })
    }

    clearBulkUpdateState()
  }

  const handleProgressUpdate = () => {
    switch (status.value) {
      case EnumBulkUpdateStatusStatus.None:
        clearBulkUpdateState()
        break
      case EnumBulkUpdateStatusStatus.Pending:
        clearDismissedNotification()
        showRunningNotification()
        break
      case EnumBulkUpdateStatusStatus.Running:
        showRunningNotification()
        break
      case EnumBulkUpdateStatusStatus.Succeeded:
      case EnumBulkUpdateStatusStatus.Failed:
        showCompletionNotifications()
        break
    }
  }

  const setStatus = (newStatus: TicketBulkUpdateStatus) => {
    persistedState.value = newStatus

    handleProgressUpdate()
  }

  const hasAgentPermission = computed(() => hasPermission('ticket.agent'))

  // Subscribe to live updates pushed by the backend as the bulk operation progresses.
  // Only active for agents, as bulk update is an agent-only feature.
  const statusSubscription = new SubscriptionHandler(
    useUserCurrentTicketBulkUpdateStatusUpdatesSubscription(() => ({
      enabled: hasAgentPermission.value,
    })),
  )

  statusSubscription.onResult((result) => {
    const update = result.data?.userCurrentTicketBulkUpdateStatusUpdates
    if (!update) return

    setStatus(update.bulkUpdateStatus)
  })

  // Inline confirmation state for bulk actions exceeding the threshold.
  // Rendered within the drag-and-drop overlay
  const confirmationPending = ref(false)
  const currentActiveEntityType = ref<DragAndDropBulkEntityType | null>(null)
  const confirmationResolver = shallowRef<((confirmed: boolean) => void) | null>(null)

  const requestBulkConfirmation = (
    type: DragAndDropBulkEntityType,
    { resolveImmediate = false } = {},
  ): Promise<boolean> => {
    if (resolveImmediate) return Promise.resolve(true)

    confirmationPending.value = true
    currentActiveEntityType.value = type

    return new Promise<boolean>((resolve) => {
      confirmationResolver.value = resolve
    })
  }

  const resolveBulkConfirmation = (confirmed: boolean) => {
    confirmationResolver.value?.(confirmed)
    confirmationResolver.value = null
    currentActiveEntityType.value = null
    confirmationPending.value = false
  }

  const confirmBulkAction = () => resolveBulkConfirmation(true)
  const cancelBulkAction = () => resolveBulkConfirmation(false)

  return {
    setTicketBulkUpdateStatus: setStatus,
    status,
    isRunning,
    confirmationPending,
    requestBulkConfirmation,
    confirmBulkAction,
    cancelBulkAction,
    currentActiveEntityType,
  }
})

if (import.meta.hot) {
  import.meta.hot.accept(acceptHMRUpdate(useTicketBulkUpdateStore, import.meta.hot))
}
