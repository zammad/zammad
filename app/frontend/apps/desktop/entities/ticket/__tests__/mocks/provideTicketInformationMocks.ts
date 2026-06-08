// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { computed, provide, reactive, ref } from 'vue'

import type { TicketQuery } from '#shared/graphql/types.ts'

import type { TicketInformation } from '#desktop/entities/ticket/types.ts'
import { items as highlightMenuItems } from '#desktop/pages/ticket/components/TicketDetailView/TicketDetailTopBar/TopBarHeader/useHighlightMenuState.ts'
import { TICKET_KEY } from '#desktop/pages/ticket/composables/useTicketInformation.ts'

export const provideTicketInformationMocks = (
  ticket: TicketQuery['ticket'],
  overrideProvideOptions: Partial<TicketInformation> = {},
) => {
  if (!ticket) {
    provide(TICKET_KEY, { ...overrideProvideOptions } as TicketInformation)

    return
  }

  provide(TICKET_KEY, {
    ticketInternalId: ref(ticket.internalId),
    ticketId: computed(() => ticket.id),
    ticket: computed(() => ticket),
    isTicketEditable: computed(() => !!ticket.policy.update),
    highlightMenu: reactive({
      activeMenuItem: highlightMenuItems[0],
      isActive: false,
      isEraserActive: false,
    }),
    ...overrideProvideOptions,
  } as TicketInformation)
}
