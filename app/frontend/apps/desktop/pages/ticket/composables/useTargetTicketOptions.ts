// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { computed, ref, shallowRef } from 'vue'

import type { ChangedFieldFunction, FormFieldValue } from '#shared/components/Form/types.ts'
import { useTicketNumberAndTitle } from '#shared/entities/ticket/composables/useTicketNumberAndTitle.ts'

import type { TicketRelationAndRecentListItem } from '#desktop/pages/ticket/components/TicketDetailView/TicketSimpleTable/types.ts'

export const useTargetTicketOptions = (
  onChangedField: ChangedFieldFunction,
  updateFieldValues: (values: Record<string, FormFieldValue>) => void,
) => {
  const targetTicketId = ref<string>()

  const formListTargetTicket = shallowRef<TicketRelationAndRecentListItem>()

  const { getTicketNumberWithTitle } = useTicketNumberAndTitle()

  const formListTargetTicketOptions = computed(() => {
    if (!formListTargetTicket.value) return

    return [
      {
        value: formListTargetTicket.value.id,
        label: getTicketNumberWithTitle(
          formListTargetTicket.value.number,
          formListTargetTicket.value.title,
        ),
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
