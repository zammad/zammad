// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import {
  NotificationTypes,
  useNotifications,
} from '#shared/components/CommonNotifications/index.ts'
import {
  EnumBulkUpdateStatusStatus,
  type TicketBulkPerformInput,
  type TicketBulkSelectorInput,
} from '#shared/graphql/types.ts'
import MutationHandler from '#shared/server/apollo/handler/MutationHandler.ts'

import { useTicketUpdateBulkMutation } from '#desktop/entities/ticket/graphql/mutations/updateBulk.api.ts'
import { useTicketBulkUpdateStore } from '#desktop/entities/user/current/stores/ticketBulkUpdate.ts'

import type { BulkUpdateResult } from '../types'

export const useTicketBulkUpdate = () => {
  const { setTicketBulkUpdateStatus } = useTicketBulkUpdateStore()

  const updateBulkMutation = new MutationHandler(useTicketUpdateBulkMutation(), {
    errorShowNotification: false,
  })

  const { notify } = useNotifications()

  const notifyBulkSuccess = (count: number, durationMS?: number) => {
    notify({
      id: 'ticket-bulk-update-succeeded',
      type: NotificationTypes.Success,
      message: __('Bulk action successful for %s ticket(s).'),
      messagePlaceholder: [count.toString()],
      ...(durationMS && { durationMS: 5000 }),
    })
  }

  const notifyBulkError = (count: number) => {
    notify({
      id: 'ticket-bulk-update-failed',
      type: NotificationTypes.Error,
      message: __('Bulk action failed for %s ticket(s). Check attribute values and try again.'),
      messagePlaceholder: [count.toString()],
      durationMS: 5000,
    })
  }

  const sendBulkUpdate = async (
    selector: TicketBulkSelectorInput,
    perform: TicketBulkPerformInput,
    fallbackTotal?: number,
  ): Promise<BulkUpdateResult | null> => {
    const result = await updateBulkMutation.send({ selector, perform })

    if (!result) return null

    const total = result.ticketUpdateBulk?.total ?? fallbackTotal ?? 0

    if (result.ticketUpdateBulk?.async) {
      setTicketBulkUpdateStatus({
        status: EnumBulkUpdateStatusStatus.Pending,
        processedCount: 0,
        total,
      })

      return { async: true, total }
    }

    return {
      async: false,
      total,
      failedCount: result.ticketUpdateBulk?.failedCount ?? 0,
      invalidTicketIds: result.ticketUpdateBulk?.invalidTicketIds ?? [],
    }
  }

  return { sendBulkUpdate, notifyBulkSuccess, notifyBulkError }
}
