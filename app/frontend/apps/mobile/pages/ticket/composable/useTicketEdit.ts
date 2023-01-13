// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { ComputedRef, ShallowRef } from 'vue'
import { computed, reactive, ref, watch } from 'vue'
import type { FormValues, FormRef, FormData } from '@shared/components/Form'
import { useObjectAttributeFormData } from '@shared/entities/object-attributes/composables/useObjectAttributeFormData'
import { useObjectAttributes } from '@shared/entities/object-attributes/composables/useObjectAttributes'
import type { TicketUpdateInput } from '@shared/graphql/types'
import { EnumObjectManagerObjects } from '@shared/graphql/types'
import { MutationHandler } from '@shared/server/apollo/handler'
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
    // show Zammad user as empty
    initialTicketValue.owner_id = ownerInternalId === 1 ? null : ownerInternalId

    form.value?.resetForm(initialTicketValue, ticket, {
      // don't reset to new values, if user changes something
      // if ticket is different, it's probably navigation to another ticket,
      // so we can safely reset the form
      resetDirty: ticketId !== ticket.id,
    })
  })

  const isTicketFormGroupValid = computed(() => {
    const ticketGroup = form.value?.formNode?.at('ticket')
    return !!ticketGroup?.context?.state.valid
  })

  const newTicketArticleRequested = ref(false)
  const newTicketArticlePresent = ref(false)

  const articleFormGroupNode = computed(() => {
    if (!newTicketArticlePresent.value && !newTicketArticleRequested.value)
      return undefined

    return form.value?.formNode?.at('article')
  })

  const isArticleFormGroupValid = computed(() => {
    return !!articleFormGroupNode.value?.context?.state.valid
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

    // TODO: Add article handling, when needed

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
    isTicketFormGroupValid,
    isArticleFormGroupValid,
    articleFormGroupNode,
    newTicketArticleRequested,
    newTicketArticlePresent,
    editTicket,
  }
}
