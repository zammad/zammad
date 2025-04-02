// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { storeToRefs } from 'pinia'
import { computed, ref, shallowRef } from 'vue'

import type {
  ChangedFieldFunction,
  FormFieldValue,
} from '#shared/components/Form/types.ts'
import { getTicketNumberWithHook } from '#shared/entities/ticket/composables/getTicketNumber.ts'
import { useApplicationStore } from '#shared/stores/application.ts'

import type { TicketRelationAndRecentListItem } from '#desktop/pages/ticket/components/TicketDetailView/TicketSimpleTable/types.ts'

export const useTargetTicketOptions = (
  onChangedField: ChangedFieldFunction,
  updateFieldValues: (values: Record<string, FormFieldValue>) => void,
) => {
  const { config } = storeToRefs(useApplicationStore())

  const targetTicketId = ref<string>()

  const formListTargetTicket = shallowRef<TicketRelationAndRecentListItem>()

  const formListTargetTicketOptions = computed(() => {
    if (!formListTargetTicket.value) return

    return [
      {
        value: formListTargetTicket.value.id,
        label: `${getTicketNumberWithHook(config.value.ticket_hook, formListTargetTicket.value.number)} - ${formListTargetTicket.value.title}`,
        heading: formListTargetTicket.value.customer.fullname,
        ticket: formListTargetTicket.value,
      },
    ]
  })

  onChangedField('targetTicketId', (value) => {
    targetTicketId.value = (value as string) ?? undefined

    if (formListTargetTicket.value?.id === value) return
    formListTargetTicket.value = undefined
  })

  const handleTicketClick = (ticket: TicketRelationAndRecentListItem) => {
    updateFieldValues({
      targetTicketId: ticket.id,
    })
    formListTargetTicket.value = ticket
  }

  return {
    formListTargetTicketOptions,
    targetTicketId,
    handleTicketClick,
  }
}
