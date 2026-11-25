// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { waitFor, within } from '@testing-library/vue'

import { visitView } from '#tests/support/components/visitView.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'
import { EnumTextDirection } from '#shared/graphql/types.ts'
import { useLocaleStore } from '#shared/stores/locale.ts'

import {
  mockDefaultOverviewQueries,
  mockDefaultTicketsCachedByOverview,
  mockEmptyTicketsCachedByOverview,
} from './mocks/ticket-overviews-mocks.ts'

const setTextDirection = (dir: EnumTextDirection) => {
  useLocaleStore().localeData = { dir } as ReturnType<typeof useLocaleStore>['localeData']
}

const visitOverview = async () => {
  const view = await visitView('tickets/view/my_assigned')

  const table = await view.findByRole('table', { name: 'Overview: My Assigned Tickets' })

  await waitFor(() => expect(within(table).getAllByTestId('table-row')).toHaveLength(2))

  return { view, rows: within(table).getAllByTestId('table-row') }
}

describe('TicketOverviews keyboard navigation', () => {
  beforeEach(() => {
    mockPermissions(['ticket.agent'])
    mockDefaultOverviewQueries()

    mockDefaultTicketsCachedByOverview({
      edges: [1, 2].map((index) => ({
        __typename: 'TicketEdge',
        node: createDummyTicket({ ticketId: String(index), title: `Ticket ${index}` }),
        cursor: `cursor-${index}`,
      })),
      totalCount: 2,
    })
  })

  it('enters the list with the arrow keys while nothing has the focus', async () => {
    const { view, rows } = await visitOverview()

    ;(document.activeElement as HTMLElement | null)?.blur()

    await view.events.keyboard('{ArrowDown}')

    expect(rows[0]).toHaveFocus()
  })

  it('moves between the list and the overview sidebar with left and right', async () => {
    const { view, rows } = await visitOverview()

    rows[0].focus()
    await view.events.keyboard('{ArrowDown}')
    expect(rows[1]).toHaveFocus()

    await view.events.keyboard('{ArrowLeft}')

    const sidebar = view.getByRole('complementary', { name: 'second level navigation sidebar' })
    const activeOverview = within(sidebar)
      .getAllByRole('link')
      .find((link) => link.getAttribute('aria-current') === 'page')

    expect(activeOverview).toHaveTextContent('My Assigned Tickets')
    expect(activeOverview).toHaveFocus()

    await view.events.keyboard('{ArrowRight}')

    expect(rows[1]).toHaveFocus()
  })

  it('swaps left and right for a right-to-left language', async () => {
    const { view, rows } = await visitOverview()

    setTextDirection(EnumTextDirection.Rtl)

    rows[0].focus()

    await view.events.keyboard('{ArrowLeft}')
    expect(rows[0]).toHaveFocus()

    await view.events.keyboard('{ArrowRight}')

    const sidebar = view.getByRole('complementary', { name: 'second level navigation sidebar' })
    const activeOverview = within(sidebar)
      .getAllByRole('link')
      .find((link) => link.getAttribute('aria-current') === 'page')

    expect(activeOverview).toHaveFocus()

    await view.events.keyboard('{ArrowLeft}')

    expect(rows[0]).toHaveFocus()

    setTextDirection(EnumTextDirection.Ltr)
  })

  it('moves over the overview links while an overview has no tickets', async () => {
    mockEmptyTicketsCachedByOverview()

    const view = await visitView('tickets/view/my_assigned')

    const navigation = await view.findByRole('navigation', { name: 'Overview navigation list' })
    const links = await within(navigation).findAllByRole('link')

    expect(await view.findByRole('heading', { level: 2 })).toHaveTextContent('Empty overview')
    expect(view.queryByRole('table')).not.toBeInTheDocument()

    ;(document.activeElement as HTMLElement | null)?.blur()

    await view.events.keyboard('{ArrowDown}')
    expect(links[0]).toHaveAttribute('aria-current', 'page')
    expect(links[0]).toHaveFocus()

    await view.events.keyboard('{ArrowDown}')
    expect(links[1]).toHaveFocus()
  })
})
