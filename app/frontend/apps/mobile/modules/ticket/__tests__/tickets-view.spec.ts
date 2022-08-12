// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { EnumOrderDirection } from '@shared/graphql/types'
import { waitFor } from '@testing-library/vue'
import { visitView } from '@tests/support/components/visitView'
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

  const plusSign = view.getByIconName('plus')

  expect(plusSign, 'can create a new ticket from here').toBeInTheDocument()
  expect(view.getLinkFromElement(plusSign)).toHaveAttribute(
    'href',
    '/#ticket/create',
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
    view.getByIconName('long-arrow-down'),
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

it('pagination loads additional list', async () => {
  const ticketOverviewsApi = mockTicketsByOverview([ticketDefault], {
    hasNextPage: true,
    endCursor: 'cursor',
  })

  const view = await visitView(`/tickets/view`)

  await waitFor(() => view.getByText('Ticket 1'))

  document.documentElement.scrollTop = 1000
  document.dispatchEvent(
    new Event('scroll', { bubbles: true, cancelable: true }),
  )

  await waitForNextTick()

  expect(ticketOverviewsApi.spies.resolve).toHaveBeenCalledWith(
    expect.objectContaining({
      cursor: 'cursor',
    }),
  )
})

it("pagination doesn't load if it is already loading more", async () => {
  const ticketOverviewsApi = mockTicketsByOverview([ticketDefault], {
    hasNextPage: true,
    endCursor: 'cursor',
  })

  const view = await visitView(`/tickets/view`)

  await waitFor(() => view.getByTestId('overview'))

  document.documentElement.scrollTop = 1000
  document.dispatchEvent(
    new Event('scroll', { bubbles: true, cancelable: true }),
  )

  await waitForNextTick()

  expect(ticketOverviewsApi.spies.resolve).not.toHaveBeenCalledWith(
    expect.objectContaining({
      cursor: 'cursor',
    }),
  )
})
