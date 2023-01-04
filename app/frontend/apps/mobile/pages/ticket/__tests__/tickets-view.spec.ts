// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { EnumOrderDirection } from '@shared/graphql/types'
import { waitFor } from '@testing-library/vue'
import { visitView } from '@tests/support/components/visitView'
import { mockApplicationConfig } from '@tests/support/mock-applicationConfig'
import { mockTicketOverviews } from '@tests/support/mocks/ticket-overviews'
import { waitForNextTick } from '@tests/support/utils'
import { stringifyQuery } from 'vue-router'
import { mockTicketsByOverview, ticketDefault } from './mocks/overview'

beforeEach(() => {
  mockTicketOverviews()
})

it('see default list when opening page', async () => {
  mockTicketsByOverview([])

  const view = await visitView('/tickets/view')

  const plusSign = view.getByIconName('mobile-add')

  expect(plusSign, 'can create a new ticket from here').toBeInTheDocument()
  expect(view.getLinkFromElement(plusSign)).toHaveAttribute(
    'href',
    '/tickets/create',
  )

  await waitForNextTick(true)

  expect(
    await view.findByTestId('overview'),
    'has default overview',
  ).toHaveTextContent('Overview 1')

  expect(
    await view.findByTestId('column'),
    'has default column',
  ).toHaveTextContent('Created at')

  expect(
    view.getByIconName('mobile-arrow-down'),
    'descending by default',
  ).not.toHaveClass('rotate-180')

  expect(
    await view.findByText('No entries'),
    'see a message when nothing is found',
  ).toBeInTheDocument()

  expect(window.location.pathname).toBe('/tickets/view/overview_1')
})

it('can filter by overview type', async () => {
  const ticketsMock = mockTicketsByOverview()

  const view = await visitView('/tickets/view')

  const overview = await view.findByTestId('overview')
  await view.events.click(overview)
  await view.events.click(view.getByText('Overview 1'))

  expect(ticketsMock.spies.resolve).toHaveBeenCalledWith(
    expect.objectContaining({
      orderBy: 'created_at',
      orderDirection: EnumOrderDirection.Descending,
      overviewId: '1',
    }),
  )

  const ticketItem = view.getByText('Ticket 1')

  expect(ticketItem).toBeInTheDocument()
  expect(view.getLinkFromElement(ticketItem)).toHaveAttribute(
    'href',
    '/tickets/1',
  )
})

it('can filter by columns and direction', async () => {
  const ticketsMock = mockTicketsByOverview()

  const view = await visitView('/tickets/view')

  const columnSelector = await view.findByTestId('column')
  await view.events.click(columnSelector)
  await view.events.click(view.getByText('Updated at'))
  await view.events.click(view.getByText('ascending'))

  expect(ticketsMock.spies.resolve).toHaveBeenCalledWith(
    expect.objectContaining({
      orderBy: 'updated_at',
      orderDirection: EnumOrderDirection.Ascending,
      overviewId: '1',
    }),
  )

  expect(view.getByText('Ticket 1')).toBeInTheDocument()
})

it('can filter by type and columns and direction', async () => {
  const ticketsMock = mockTicketsByOverview()

  const view = await visitView('/tickets/view')

  const overview = await view.findByTestId('overview')
  await view.events.click(overview)
  await view.events.click(view.getByText('Overview 1'))

  const columnSelector = view.getByTestId('column')
  await view.events.click(columnSelector)
  await view.events.click(view.getByText('Updated at'))
  await view.events.click(view.getByText('ascending'))

  expect(ticketsMock.spies.resolve).toHaveBeenCalledWith(
    expect.objectContaining({
      overviewId: '1',
      orderBy: 'updated_at',
      orderDirection: EnumOrderDirection.Ascending,
    }),
  )

  expect(view.getByText('Ticket 1')).toBeInTheDocument()
})

it('takes filter from query', async () => {
  const ticketsMock = mockTicketsByOverview()

  const query = stringifyQuery({
    column: 'number',
    direction: EnumOrderDirection.Ascending,
  })

  const view = await visitView(`/tickets/view?${query}`)

  await view.findByTestId('overview')

  await waitFor(() => {
    expect(ticketsMock.spies.resolve).toHaveBeenCalledWith(
      expect.objectContaining({
        overviewId: '1',
        orderBy: 'number',
        orderDirection: EnumOrderDirection.Ascending,
      }),
    )
  })
})

describe('paginating ticket list', () => {
  const emulateScroll = async (scroll: number) => {
    document.documentElement.scrollTop = scroll
    document.dispatchEvent(
      new Event('scroll', { bubbles: true, cancelable: true }),
    )

    await waitForNextTick()
  }

  it("doesn't load more, when there is nothing to load", async () => {
    const ticketOverviewsApi = mockTicketsByOverview([ticketDefault()], {
      hasNextPage: false,
      endCursor: 'cursor',
    })

    mockApplicationConfig({
      ui_ticket_overview_ticket_limit: 2000,
    })

    const view = await visitView(`/tickets/view`)

    await waitFor(() => view.getByText('Ticket 1'))

    expect(
      view.queryByRole('button', { name: 'load 10 more' }),
    ).not.toBeInTheDocument()

    await emulateScroll(1000)

    expect(ticketOverviewsApi.spies.resolve).not.toHaveBeenCalledWith(
      expect.objectContaining({
        cursor: 'cursor',
      }),
    )
  })

  it('load more button loads more tickets', async () => {
    const ticketOverviewsApi = mockTicketsByOverview([ticketDefault()], {
      hasNextPage: true,
      endCursor: 'cursor',
    })

    mockApplicationConfig({
      ui_ticket_overview_ticket_limit: 2000,
    })

    const view = await visitView(`/tickets/view`)

    await waitFor(() => view.getByText('Ticket 1'))

    const loadMoreButton = view.getByRole('button', { name: 'load 10 more' })

    expect(loadMoreButton).toBeInTheDocument()
    await view.events.click(loadMoreButton)

    expect(ticketOverviewsApi.spies.resolve).toHaveBeenCalledWith(
      expect.objectContaining({
        cursor: 'cursor',
      }),
    )

    // page now has 2 links to tickets
    // the last link before pressing "load more" has the focus
    expect(view.getAllByRole('link', { name: /Ticket 1/ })[0]).toHaveFocus()
  })

  it('pagination loads additional list', async () => {
    const ticketOverviewsApi = mockTicketsByOverview([ticketDefault()], {
      hasNextPage: true,
      endCursor: 'cursor',
    })

    mockApplicationConfig({
      ui_ticket_overview_ticket_limit: 2000,
    })

    const view = await visitView(`/tickets/view`)

    await waitFor(() => view.getByText('Ticket 1'))

    await emulateScroll(1000)

    expect(ticketOverviewsApi.spies.resolve).toHaveBeenCalledWith(
      expect.objectContaining({
        cursor: 'cursor',
      }),
    )
  })

  it("pagination doesn't load if it is already loading more", async () => {
    const ticketOverviewsApi = mockTicketsByOverview([ticketDefault()], {
      hasNextPage: true,
      endCursor: 'cursor',
    })

    const view = await visitView(`/tickets/view`)

    await waitFor(() => view.getByTestId('overview'))
    await emulateScroll(1000)

    expect(ticketOverviewsApi.spies.resolve).not.toHaveBeenCalledWith(
      expect.objectContaining({
        cursor: 'cursor',
      }),
    )
  })
})
