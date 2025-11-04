// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { computed, ref } from 'vue'

import { renderComponent } from '#tests/support/components/index.ts'

import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'
import type { Ticket } from '#shared/graphql/types.ts'

import TicketInformationBadgeList from '#desktop/pages/ticket/components/TicketDetailView/TicketDetailTopBar/TopBarHeader/TicketInformation/TicketInformationBadgeList.vue'
import { mockTicketChecklistQuery } from '#desktop/pages/ticket/graphql/queries/ticketChecklist.mocks.ts'

let ticket: Ticket

vi.mock('#desktop/pages/ticket/composables/useTicketInformation.ts', () => ({
  useTicketInformation: () => ({
    ticketInternalId: ref(ticket.internalId),
    ticketId: computed(() => ticket.id),
    ticket: computed(() => ticket),
    isTicketEditable: computed(() => !!ticket?.policy.update),
  }),
}))

vi.mock('#desktop/pages/ticket/composables/useTicketSidebar.ts', () => ({
  useTicketSidebar: () => ({}),
}))

vi.hoisted(() => {
  vi.setSystemTime(new Date('2024-11-11T11:11:11Z'))
})

describe('TicketInformationBadgeList', () => {
  beforeEach(() => {
    mockTicketChecklistQuery({
      ticketChecklist: null,
    })
  })

  it('displays a open ticket badge', () => {
    ticket = createDummyTicket()
    const wrapper = renderComponent(TicketInformationBadgeList, {})

    const badges = wrapper.getAllByTestId('common-badge')

    expect(badges.at(0)).toHaveTextContent(ticket.state.name)
  })

  it('displays a ticket priority badge', () => {
    ticket = createDummyTicket()
    const wrapper = renderComponent(TicketInformationBadgeList, {})

    const badges = wrapper.getAllByTestId('common-badge')

    expect(badges.at(1)).toHaveTextContent(ticket.priority.name)
  })

  it('do not display a ticket priority badge if user has no agent permissions', () => {
    ticket = createDummyTicket({ defaultPolicy: { update: false, agentReadAccess: false } })

    const wrapper = renderComponent(TicketInformationBadgeList, {})

    const badges = wrapper.getAllByTestId('common-badge')

    // Verify that no badge contains priority content.
    badges.forEach((badge) => {
      expect(badge).not.toHaveTextContent(ticket.priority.name)
    })
  })

  it('displays a ticket created at badge', () => {
    ticket = createDummyTicket()
    const wrapper = renderComponent(TicketInformationBadgeList, {})

    const badges = wrapper.getAllByTestId('common-badge')

    expect(badges.at(2)).toHaveTextContent('Created 13 years ago')
  })
})
