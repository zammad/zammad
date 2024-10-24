// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { computed, ref } from 'vue'

import { renderComponent } from '#tests/support/components/index.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'

import type { TicketById } from '#shared/entities/ticket/types.ts'
import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'
import { EnumTicketStateColorCode } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import ChecklistBadgeList from '#desktop/pages/ticket/components/TicketDetailView/TicketDetailTopBar/TopBarHeader/TicketInformation/TicketInformationBadgeList/ChecklistBadgeList.vue'
import { TICKET_KEY } from '#desktop/pages/ticket/composables/useTicketInformation.ts'

const switchSidebar = vi.fn()

vi.mock('#desktop/pages/ticket/composables/useTicketSidebar.ts', () => ({
  useTicketSidebar: () => ({
    switchSidebar,
  }),
}))

const mockTicket = (ticket: TicketById) => {
  return {
    ticketId: computed(() => ticket.id),
    ticket: computed(() => ticket),
    form: ref(),
    showTicketArticleReplyForm: () => {},
    isTicketEditable: computed(() => true),
    newTicketArticlePresent: ref(false),
    ticketInternalId: computed(() => ticket.internalId),
  }
}

describe('TicketChecklistBadges', () => {
  it('hides badges if no checklist is present', () => {
    const data = createDummyTicket()

    const wrapper = renderComponent(ChecklistBadgeList, {
      router: true,
      provide: [[TICKET_KEY, mockTicket(data)]],
    })
    expect(wrapper.queryByTestId('common-badge')).not.toBeInTheDocument()
  })

  it('displays checked count', async () => {
    const data = createDummyTicket({
      checklist: {
        id: convertToGraphQLId('Checklist', 1),
        completed: false,
        incomplete: 3,
        total: 5,
        complete: 2,
      },
    })

    const wrapper = renderComponent(ChecklistBadgeList, {
      router: true,
      provide: [[TICKET_KEY, mockTicket(data)]],
    })

    expect(wrapper.getByIconName('checklist')).toBeInTheDocument()

    expect(
      wrapper.getByRole('button', { name: 'Open Checklist' }),
    ).toHaveTextContent('checked2 of 5') // because of margin
  })

  it('opens checklist in sidebar if checked badge is clicked ', async () => {
    const data = createDummyTicket({
      checklist: {
        id: convertToGraphQLId('Checklist', 1),
        completed: false,
        incomplete: 3,
        total: 5,
        complete: 2,
      },
    })

    const wrapper = renderComponent(ChecklistBadgeList, {
      router: true,
      provide: [[TICKET_KEY, mockTicket(data)]],
    })

    await wrapper.events.click(
      wrapper.getByRole('button', { name: 'Open Checklist' }),
    )

    expect(switchSidebar).toHaveBeenCalledWith('checklist')
  })

  it('displays tracked in ticket references for single item', () => {
    mockApplicationConfig({
      ticket_hook: 'Hook#',
    })

    const data = createDummyTicket({
      checklist: {
        id: convertToGraphQLId('Checklist', 1),
        completed: false,
        incomplete: 2,
        total: 3,
        complete: 1,
      },
      referencingChecklistTickets: [
        {
          state: {
            name: EnumTicketStateColorCode.Open,
            id: convertToGraphQLId('TicketState', 1),
          },
          number: '123',
          title: 'Foo Example',
          internalId: 1,
          id: convertToGraphQLId('Ticket', 1),
          stateColorCode: EnumTicketStateColorCode.Open,
        },
      ],
    })

    const wrapper = renderComponent(ChecklistBadgeList, {
      provide: [[TICKET_KEY, mockTicket(data)]],
    })

    const badges = wrapper.getAllByTestId('common-badge')

    expect(badges.at(1)).toHaveTextContent('tracked inHook#123')
  })

  it('displays tracked in ticket references for multiple items', async () => {
    mockApplicationConfig({
      ticket_hook: 'Hook#',
    })

    const data = createDummyTicket({
      checklist: {
        id: convertToGraphQLId('Checklist', 1),
        completed: false,
        total: 3,
        incomplete: 2,
        complete: 1,
      },
      referencingChecklistTickets: [
        {
          state: {
            name: EnumTicketStateColorCode.Open,
            id: convertToGraphQLId('TicketState', 1),
          },
          number: '456',
          title: 'Bar Title',
          internalId: 23,
          id: convertToGraphQLId('Ticket', 23),
          stateColorCode: EnumTicketStateColorCode.Open,
        },
        {
          state: {
            name: EnumTicketStateColorCode.Open,
            id: convertToGraphQLId('TicketState', 2),
          },
          number: '123',
          title: 'Foo Title',
          internalId: 2,
          id: convertToGraphQLId('Ticket', 2),
          stateColorCode: EnumTicketStateColorCode.Open,
        },
      ],
    })

    const wrapper = renderComponent(ChecklistBadgeList, {
      router: true,
      provide: [[TICKET_KEY, mockTicket(data)]],
    })

    await wrapper.events.click(
      wrapper.getByRole('button', { name: 'Show tracking tickets' }),
    )

    expect(
      await wrapper.findByText('Tracked as checklist item in'),
    ).toBeInTheDocument()

    const badges = wrapper.getAllByTestId('common-badge')

    expect(badges.at(1)).toHaveTextContent('tracked in2')

    expect(wrapper.getByRole('link', { name: 'Hook#123' })).toHaveTextContent(
      'Foo Title',
    )

    expect(wrapper.getByRole('link', { name: 'Hook#123' })).toHaveAttribute(
      'href',
      '/desktop/tickets/2',
    )

    expect(wrapper.getByRole('link', { name: 'Hook#456' })).toHaveAttribute(
      'href',
      '/desktop/tickets/23',
    )
  })

  it('does not show badge if all items are checked', async () => {
    const data = createDummyTicket({
      checklist: {
        id: convertToGraphQLId('Checklist', 1),
        completed: false,
        total: 3,
        incomplete: 0,
        complete: 3,
      },
    })

    const wrapper = renderComponent(ChecklistBadgeList, {
      router: true,
      provide: [[TICKET_KEY, mockTicket(data)]],
    })

    expect(
      wrapper.queryByRole('button', { name: 'checked3 of 3' }),
    ).not.toBeInTheDocument()
  })
})
