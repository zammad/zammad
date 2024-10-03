// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import {
  NotificationTypes,
  useNotifications,
} from '#shared/components/CommonNotifications/index.ts'
import type { FormSubmitData } from '#shared/components/Form/types.ts'
import { useTicketCustomerUpdateMutation } from '#shared/entities/ticket/graphql/mutations/customerUpdate.api.ts'
import type {
  TicketById,
  TicketCustomerUpdateFormData,
} from '#shared/entities/ticket/types.ts'
import UserError from '#shared/errors/UserError.ts'
import type { TicketCustomerUpdateInput } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import { MutationHandler } from '#shared/server/apollo/handler/index.ts'

import type { Ref } from 'vue'

export const useTicketChangeCustomer = (
  ticket: Ref<TicketById>,
  options?: { onSuccess: () => void },
) => {
  const { notify } = useNotifications()

  const changeCustomerMutation = new MutationHandler(
    useTicketCustomerUpdateMutation(),
  )

  const changeCustomer = async (
    formData: FormSubmitData<TicketCustomerUpdateFormData>,
  ) => {
    const input = {
      customerId: convertToGraphQLId('User', formData.customer_id),
    } as TicketCustomerUpdateInput

    if (formData.organization_id) {
      input.organizationId = convertToGraphQLId(
        'Organization',
        formData.organization_id,
      )
    }

    try {
      const result = await changeCustomerMutation.send({
        ticketId: ticket.value.id,
        input,
      })

      if (result) {
        options?.onSuccess?.()

        notify({
          id: 'ticket-customer-updated',
          type: NotificationTypes.Success,
          message: __('Ticket customer updated successfully.'),
        })

        return result
      }
    } catch (errors) {
      if (errors instanceof UserError) {
        notify({
          id: 'ticket-customer-update-error',
          message: errors.generalErrors[0],
          type: NotificationTypes.Error,
        })
      }
    }
  }

  return { changeCustomer }
}
