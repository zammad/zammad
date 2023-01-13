// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { FormValues } from '@shared/components/Form'
import type { FormRef } from '@shared/components/Form/composable'
import type { FormData } from '@shared/components/Form/types'
import { useObjectAttributeFormData } from '@shared/entities/object-attributes/composables/useObjectAttributeFormData'
import { useObjectAttributes } from '@shared/entities/object-attributes/composables/useObjectAttributes'
import type { TicketUpdateInput } from '@shared/graphql/types'
import { EnumObjectManagerObjects } from '@shared/graphql/types'
import { MutationHandler } from '@shared/server/apollo/handler'
import type { ComputedRef, ShallowRef } from 'vue'
import { reactive, watch } from 'vue'
import type { TicketById } from '@shared/entities/ticket/types'
import { useTicketUpdateMutation } from '../graphql/mutations/update.api'

export const useTicketEdit = (
  ticket: ComputedRef<TicketById | undefined>,
  form: ShallowRef<FormRef | undefined>,
) => {
  const initialTicketValue = reactive<FormValues>({})
  const mutationUpdate = new MutationHandler(useTicketUpdateMutation({}))

  watch(ticket, (ticket) => {
    if (!ticket) {
      return
    }
    const ticketId = initialTicketValue.id || ticket.id
    const { internalId: ownerInternalId } = ticket.owner
    initialTicketValue.id = ticket.id
    initialTicketValue.title = ticket.title
    // show Zammad user as empty
    initialTicketValue.owner_id = ownerInternalId === 1 ? null : ownerInternalId
    const attributes =
      ticket.objectAttributeValues?.reduce(
        (acc: Record<string, unknown>, cur) => {
          acc[cur.attribute.name] = cur.value
          return acc
        },
        {},
      ) || {}
    Object.assign(initialTicketValue, attributes)
    form.value?.resetForm(initialTicketValue, ticket, {
      // don't reset to new values, if user changes something
      // if ticket is different, it's probably navigation to another ticket,
      // so we can safely reset the form
      resetDirty: ticketId !== ticket.id,
    })
  })

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
      ticketId: ticket.value.id,
      input: {
        ...internalObjectAttributeValues,
        objectAttributeValues: additionalObjectAttributeValues,
      } as TicketUpdateInput,
    })
  }

  return {
    initialTicketValue,
    editTicket,
  }
}
