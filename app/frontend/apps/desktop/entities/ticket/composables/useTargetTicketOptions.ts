// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { computed, ref, shallowRef } from 'vue'

import type { ChangedFieldFunction, FormFieldValue } from '#shared/components/Form/types.ts'
import { useTicketNumberAndTitle } from '#shared/entities/ticket/composables/useTicketNumberAndTitle.ts'

import type { TicketRelationAndRecentListItem } from '#desktop/components/Ticket/TicketSimpleTable/types.ts'

// Keeps a ticket picker and a list of clickable tickets next to it in step: clicking a row selects
//   it in the field, and hands the field the option to render it with, so it needs no lookup of its
//   own for a value it was just given.
//
// `fieldName` because the two flyouts using this name their field differently - the ticket one
//   links a *target* ticket, the knowledge base one links a ticket to an answer.
export const useTargetTicketOptions = (
  onChangedField: ChangedFieldFunction,
  updateFieldValues: (values: Record<string, FormFieldValue>) => void,
  fieldName = 'targetTicketId',
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

  onChangedField(fieldName, (value) => {
    targetTicketId.value = (value as string) ?? undefined

    if (formListTargetTicket.value?.id === value) return
    formListTargetTicket.value = undefined
  })

  const handleTicketClick = (ticket: TicketRelationAndRecentListItem) => {
    updateFieldValues({
      [fieldName]: ticket.id,
    })
    formListTargetTicket.value = ticket
  }

  return {
    formListTargetTicketOptions,
    targetTicketId,
    handleTicketClick,
  }
}
