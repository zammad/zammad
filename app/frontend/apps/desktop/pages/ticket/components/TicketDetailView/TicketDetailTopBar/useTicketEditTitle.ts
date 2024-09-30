// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/
import {
  NotificationTypes,
  useNotifications,
} from '#shared/components/CommonNotifications/index.ts'
import { useTicketUpdateMutation } from '#shared/entities/ticket/graphql/mutations/update.api.ts'
import { MutationHandler } from '#shared/server/apollo/handler/index.ts'

import type { ComputedRef } from 'vue'

export const useTicketEditTitle = (ticketId: ComputedRef<string>) => {
  const { notify } = useNotifications()

  const mutationUpdate = new MutationHandler(useTicketUpdateMutation())

  const updateTitle = async (title: string) => {
    return mutationUpdate
      .send({
        ticketId: ticketId.value,
        input: { title },
        meta: {},
      })
      .then(() => {
        notify({
          type: NotificationTypes.Success,
          id: 'ticket-updated-successfully',
          message: __('Ticket updated successfully.'),
        })
      })
  }

  return { updateTitle }
}
