// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { FormValues } from '@shared/components/Form'
import type { FormFieldValue, FormData } from '@shared/components/Form/types'
import { useObjectAttributeFormData } from '@shared/entities/object-attributes/composables/useObjectAttributeFormData'
import { useObjectAttributes } from '@shared/entities/object-attributes/composables/useObjectAttributes'
import type { TicketUpdateInput } from '@shared/graphql/types'
import { EnumObjectManagerObjects } from '@shared/graphql/types'
import { MutationHandler } from '@shared/server/apollo/handler'
import type { ComputedRef } from 'vue'
import { reactive, watch } from 'vue'
import { useTicketUpdateMutation } from '../graphql/mutations/update.api'
import type { TicketById } from '../types/tickets'

export const useTicketEdit = (ticket: ComputedRef<TicketById | undefined>) => {
  const initialTicketValue = reactive<FormValues>({})
  const mutationUpdate = new MutationHandler(useTicketUpdateMutation({}))

  watch(ticket, (ticket) => {
    if (!ticket) {
      return
    }
    const { internalId } = ticket.owner
    initialTicketValue.title = ticket.title
    // show Zammad user as empty
    initialTicketValue.owner_id = internalId === 1 ? null : internalId
    // TODO form should support it out of the box
    const attributes =
      ticket.objectAttributeValues?.reduce(
        (acc: Record<string, unknown>, cur) => {
          acc[cur.attribute.name] = cur.value
          return acc
        },
        {},
      ) || {}
    Object.assign(initialTicketValue, attributes)
  })

  const updateTicketField = (key: string, value: FormFieldValue) => {
    initialTicketValue[key] = value
  }

  const { attributesLookup: objectAttributesLookup } = useObjectAttributes(
    EnumObjectManagerObjects.Ticket,
  )

  const editTicket = async (formData: FormData) => {
    if (!ticket.value) return undefined

    if (!formData.owner_id) {
      formData.owner_id = 1
    }

    const { internalObjectAttributeValues, additionalObjectAttributeValues } =
      useObjectAttributeFormData(objectAttributesLookup.value, formData)

    return mutationUpdate.send({
      ticket: {
        ticketId: ticket.value.id,
      },
      input: {
        ...internalObjectAttributeValues,
        objectAttributeValues: additionalObjectAttributeValues,
      } as TicketUpdateInput,
    })
  }

  return {
    initialTicketValue,
    updateTicketField,
    editTicket,
  }
}
