// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { nullableMock, waitForNextTick } from '#tests/support/utils.ts'

import {
  mockAutocompleteSearchTicketQuery,
  waitForAutocompleteSearchTicketQueryCalls,
} from '#shared/entities/ticket/graphql/queries/autocompleteSearchTicket.mocks.ts'
import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'
import {
  EnumLinkType,
  EnumTicketStateColorCode,
  type AutocompleteSearchTicketQuery,
} from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import {
  mockLinkAddMutation,
  waitForLinkAddMutationCalls,
} from '#desktop/entities/link/graphql/mutations/linkAdd.mocks.ts'
import { mockTicketsRecentlyViewedQuery } from '#desktop/entities/ticket/graphql/queries/ticketsRecentlyViewed.mocks.ts'

import KnowledgeBaseAnswerLinkTicketFlyout from '../KnowledgeBaseAnswerLinkTicketFlyout.vue'

const TRANSLATION_ID = convertToGraphQLId('KnowledgeBase::Answer::Translation', 1)
const TICKET_ID = convertToGraphQLId('Ticket', 42)

const ticketOption: AutocompleteSearchTicketQuery['autocompleteSearchTicket'][0] = {
  __typename: 'AutocompleteSearchTicketEntry',
  value: TICKET_ID,
  label: 'Printer on the second floor jams every other page',
  labelPlaceholder: [],
  heading: 'Ticket#123456 - Max Mustermann',
  headingPlaceholder: [],
  disabled: false,
  icon: null,
  ticket: nullableMock({
    __typename: 'Ticket',
    id: TICKET_ID,
    internalId: 42,
    number: '123456',
    state: nullableMock({
      __typename: 'TicketState' as const,
      id: convertToGraphQLId('TicketState', 1),
      name: 'open',
    }),
    stateColorCode: EnumTicketStateColorCode.Open,
  }),
}

const renderFlyout = () =>
  renderComponent(KnowledgeBaseAnswerLinkTicketFlyout, {
    props: { translationId: TRANSLATION_ID },
    form: true,
    flyout: true,
    router: true,
    store: true,
  })

const pickTicket = async (view: ReturnType<typeof renderFlyout>) => {
  await view.events.click(await view.findByLabelText('Ticket'))

  mockAutocompleteSearchTicketQuery({ autocompleteSearchTicket: [ticketOption] })

  await view.events.type(view.getByRole('searchbox'), ticketOption.label)
  await waitForAutocompleteSearchTicketQueryCalls()

  await view.events.click(await view.findByRole('option', { name: new RegExp(ticketOption.label) }))
}

describe('KnowledgeBaseAnswerLinkTicketFlyout', () => {
  it('asks for a ticket and nothing else', async () => {
    const view = renderFlyout()

    expect(view.getByRole('heading', { name: 'Link ticket', level: 2 })).toBeInTheDocument()
    expect(view.getByLabelText('Ticket')).toBeInTheDocument()

    // One flat list of related tickets, so there is no link type to pick - unlike the ticket
    //   detail view's own flyout.
    expect(view.queryByLabelText('Link type')).not.toBeInTheDocument()
  })

  // The orientation is the thing to pin down: the ticket is the *source* and the answer translation
  //   the *target*, which is what the legacy knowledge base sidebar writes too. Swapped, the link
  //   would be created for the wrong pair and would not come back out of this list.
  it('links the picked ticket to the answer translation', async () => {
    mockLinkAddMutation({
      linkAdd: {
        link: { type: EnumLinkType.Normal, item: ticketOption.ticket },
        errors: null,
      },
    })

    const view = renderFlyout()

    await pickTicket(view)

    await view.events.click(view.getByRole('button', { name: 'Link' }))

    const calls = await waitForLinkAddMutationCalls()

    expect(calls.at(-1)?.variables).toEqual({
      input: {
        sourceId: TICKET_ID,
        targetId: TRANSLATION_ID,
        type: EnumLinkType.Normal,
      },
    })
  })

  // The ticket just worked on is usually the one being documented, so it is offered instead of
  //   having to be searched for by number. Clicking a row has to reach the field, not just look
  //   selected - otherwise submitting links nothing.
  it('offers the recently viewed tickets and links the clicked one', async () => {
    mockApplicationConfig({ ticket_hook: 'Hook#' })

    // A different id from the searched one, so the assertion cannot pass on a coincidence.
    const recentTicket = createDummyTicket({ ticketId: '77', number: '654321' })

    mockTicketsRecentlyViewedQuery({ ticketsRecentlyViewed: [recentTicket] })

    mockLinkAddMutation({
      linkAdd: {
        link: { type: EnumLinkType.Normal, item: ticketOption.ticket },
        errors: null,
      },
    })

    const view = renderFlyout()

    expect(await view.findByRole('table', { name: 'Recently viewed tickets' })).toBeInTheDocument()

    await waitForNextTick()

    const rows = view.getAllByRole('row', { description: 'Select table row' })
    await view.events.click(rows[0])

    await view.events.click(view.getByRole('button', { name: 'Link' }))

    const calls = await waitForLinkAddMutationCalls()

    expect(calls.at(-1)?.variables).toEqual({
      input: {
        sourceId: recentTicket.id,
        targetId: TRANSLATION_ID,
        type: EnumLinkType.Normal,
      },
    })
  })
})
