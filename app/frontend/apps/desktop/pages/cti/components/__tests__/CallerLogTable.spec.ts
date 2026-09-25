// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import '#tests/graphql/builders/mocks.ts'

import { within } from '@testing-library/vue'

import { getGraphQLMockCalls } from '#tests/graphql/builders/mocks.ts'
import { renderComponent } from '#tests/support/components/index.ts'
import { getTestRouter } from '#tests/support/components/renderComponent.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'
import { mockRouterHooks } from '#tests/support/mock-vue-router.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import { useReactiveNow } from '#shared/composables/useReactiveNow.ts'
import {
  mockUserAddMutation,
  waitForUserAddMutationCalls,
} from '#shared/entities/user/graphql/mutations/add.mocks.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import type { ListTableProps } from '#desktop/components/CommonTable/types.ts'
import { mockUserInfoForPopoverQuery } from '#desktop/components/User/UserPopoverWithTrigger/graphql/queries/userInfoForPopover.mocks.ts'
import { CtiLogDoneUpdateDocument } from '#desktop/entities/cti/graphql/mutations/ctiLogDoneUpdate.api.ts'
import {
  mockCtiLogDoneUpdateMutation,
  waitForCtiLogDoneUpdateMutationCalls,
} from '#desktop/entities/cti/graphql/mutations/ctiLogDoneUpdate.mocks.ts'

import {
  callerLogEntries,
  callerLogHeaders,
  callFromDeletedUser,
  callFromUnknown,
  callWithCommentMatch,
  callWithPossibleCallers,
  checkedCall,
  knownCustomer,
  missedCall,
  mockUserCreateFlyoutQueries,
  outboundCall,
} from '../../__tests__/mocks/caller-log-mocks.ts'
import CallerLogTable from '../CallerLogTable.vue'

import type { CallerLogEntry } from '../../types.ts'

mockRouterHooks()

// The clock has to be a plain ref so a test can move it past the minute a fresh call is locked for.
vi.mock('#shared/composables/useReactiveNow.ts', async () => {
  const { ref } = await import('vue')
  const now = ref(new Date())

  return { useReactiveNow: () => now }
})

const reactiveNow = useReactiveNow()

const headersWithDone = ['done', ...callerLogHeaders]

const routerRoutes = [
  { path: '/', name: 'Dashboard', component: { template: 'dashboard' } },
  { path: '/tickets/create', name: 'TicketCreate', component: { template: 'ticket create' } },
  // The participants' links pass through the router too, and warn without a catch-all.
  { path: '/:pathMatch(.*)*', name: 'Error', component: { template: 'error' } },
]

const renderTable = async (props: Partial<ListTableProps<CallerLogEntry>> = {}) => {
  const wrapper = renderComponent(CallerLogTable, {
    router: true,
    routerRoutes,
    // The caller popover renders object attributes, which need the form system.
    form: true,
    flyout: true,
    props: {
      tableId: 'caller-log',
      caption: 'Caller log',
      headers: callerLogHeaders,
      items: callerLogEntries,
      totalCount: callerLogEntries.length,
      maxItems: 1000,
      loading: false,
      loadingNewPage: false,
      ...props,
    },
  })

  await waitForNextTick()

  return wrapper
}

const getRow = (wrapper: ReturnType<typeof renderComponent>, entry: CallerLogEntry) => {
  const row = wrapper.container.querySelector(`[data-item-id="${entry.id}"]`)

  expect(row).not.toBeNull()

  return row as HTMLElement
}

describe('CallerLogTable', () => {
  beforeEach(() => {
    mockPermissions(['cti.agent', 'ticket.agent'])
    mockApplicationConfig({ user_name_format: 'first_last' })
    reactiveNow.value = new Date()
  })

  it('renders the columns from the design', async () => {
    const wrapper = await renderTable()

    const headers = ['From', 'To', 'Status', 'Waiting', 'Duration', 'Time']

    headers.forEach((header) => {
      expect(wrapper.getByRole('columnheader', { name: header })).toBeInTheDocument()
    })

    expect(wrapper.queryAllByRole('button', { name: /^Sort by/ })).toHaveLength(0)
  })

  it('dims a checked entry only', async () => {
    const wrapper = await renderTable()

    expect(getRow(wrapper, checkedCall)).toHaveClass('opacity-50')
    expect(getRow(wrapper, missedCall)).not.toHaveClass('opacity-50')
  })

  it('marks an entry as handled from the checkbox', async () => {
    mockCtiLogDoneUpdateMutation({ ctiLogDoneUpdate: { log: { id: missedCall.id, done: true } } })

    const wrapper = await renderTable({
      headers: headersWithDone,
      items: [missedCall],
      totalCount: 1,
    })

    const checkbox = within(getRow(wrapper, missedCall)).getByRole('checkbox', {
      name: 'Mark as handled',
    })

    expect(checkbox).toHaveAttribute('aria-disabled', 'false')
    expect(checkbox).toHaveAttribute('tabindex', '0')

    await wrapper.events.click(checkbox)

    const calls = await waitForCtiLogDoneUpdateMutationCalls()

    expect(calls.at(-1)?.variables).toEqual({ id: missedCall.id, done: true })
  })

  it('locks the checkbox of a call that is still running and younger than a minute', async () => {
    const freshCall: CallerLogEntry = {
      ...callFromUnknown,
      createdAt: new Date(reactiveNow.value.getTime() - 30_000).toISOString(),
    }

    const wrapper = await renderTable({
      headers: headersWithDone,
      items: [freshCall],
      totalCount: 1,
    })

    const checkbox = within(getRow(wrapper, freshCall)).getByRole('checkbox')

    expect(checkbox).toHaveAttribute('aria-disabled', 'true')
    expect(checkbox).toHaveAttribute('tabindex', '-1')
    expect(checkbox).toHaveClass('cursor-not-allowed!', 'opacity-50')
    expect(checkbox).toHaveAccessibleName(
      'Can be marked as handled once the call has ended or is a minute old',
    )

    await wrapper.events.click(checkbox)
    await waitForNextTick()

    expect(getGraphQLMockCalls(CtiLogDoneUpdateDocument)).toHaveLength(0)
  })

  it('unlocks the checkbox once the call is a minute old', async () => {
    const freshCall: CallerLogEntry = {
      ...callFromUnknown,
      createdAt: reactiveNow.value.toISOString(),
    }

    const wrapper = await renderTable({
      headers: headersWithDone,
      items: [freshCall],
      totalCount: 1,
    })

    const checkbox = within(getRow(wrapper, freshCall)).getByRole('checkbox')

    expect(checkbox).toHaveAttribute('aria-disabled', 'true')

    reactiveNow.value = new Date(reactiveNow.value.getTime() + 61_000)
    await waitForNextTick()

    expect(checkbox).toHaveAttribute('aria-disabled', 'false')
    expect(checkbox).toHaveAttribute('tabindex', '0')
    expect(checkbox).not.toHaveClass('cursor-not-allowed!')
    expect(checkbox).toHaveAccessibleName('Mark as not handled')
  })

  it('derives the status from the state and the comment', async () => {
    const wrapper = await renderTable()

    expect(within(getRow(wrapper, missedCall)).getByText('Not reached')).toBeInTheDocument()
    expect(
      within(getRow(wrapper, callWithPossibleCallers)).getByText('Ringing…'),
    ).toBeInTheDocument()
    expect(within(getRow(wrapper, callFromUnknown)).getByText('Connected')).toBeInTheDocument()
    expect(within(getRow(wrapper, outboundCall)).getByText('Busy')).toBeInTheDocument()
  })

  it('shows a call ended for a normal clearing', async () => {
    const wrapper = await renderTable({ items: [checkedCall], totalCount: 1 })

    const statusCell = within(getRow(wrapper, checkedCall)).getAllByRole('cell')[2]

    expect(within(statusCell).getByLabelText('Inbound call')).toBeInTheDocument()
    expect(statusCell).toHaveTextContent('Call ended')
  })

  it('shows a skeleton while loading', async () => {
    const wrapper = await renderTable({ items: [], totalCount: 0, loading: true })

    expect((await wrapper.findAllByRole('progressbar')).length).toBeGreaterThan(0)
    expect(wrapper.queryByRole('table', { name: 'Caller log' })).not.toBeInTheDocument()
  })

  it('picks the status icon from the outcome of the call', async () => {
    const wrapper = await renderTable()

    const statusIcon = (entry: CallerLogEntry) =>
      within(getRow(wrapper, entry)).getByLabelText(
        entry.direction === 'in' ? 'Inbound call' : 'Outbound call',
      )

    const icons: [CallerLogEntry, string][] = [
      [callWithPossibleCallers, 'telephone-inbound'],
      [missedCall, 'telephone'],
      [checkedCall, 'telephone-v'],
      [callFromUnknown, 'telephone-v'],
      [outboundCall, 'telephone-x'],
    ]

    icons.forEach(([entry, icon]) => {
      expect(statusIcon(entry).querySelector('use')).toHaveAttribute('href', `#icon-${icon}`)
    })
  })

  it('lifts a ringing and a connected call out of the muted palette', async () => {
    const wrapper = await renderTable()

    const ringingRow = getRow(wrapper, callWithPossibleCallers)

    expect(within(ringingRow).getByLabelText('Inbound call')).toHaveClass(
      'text-yellow-500 animate-vibrate motion-reduce:animate-none',
    )
    expect(within(ringingRow).getByText('Ringing…')).toHaveClass('text-black! dark:text-white!')

    // A call in progress colors the icon only, its label stays muted.
    const connectedRow = getRow(wrapper, callFromUnknown)

    expect(within(connectedRow).getByLabelText('Inbound call')).toHaveClass('text-green-400')
    expect(within(connectedRow).getByText('Connected')).toHaveClass(
      'text-gray-100 dark:text-neutral-400',
    )

    const missedRow = getRow(wrapper, missedCall)

    expect(within(missedRow).getByLabelText('Inbound call')).toHaveClass(
      'text-stone-200 dark:text-neutral-500',
    )
    expect(within(missedRow).getByText('Not reached')).toHaveClass(
      'text-gray-100 dark:text-neutral-400',
    )
  })

  it('shows the call direction next to the status', async () => {
    const wrapper = await renderTable()

    expect(within(getRow(wrapper, missedCall)).getByLabelText('Inbound call')).toBeInTheDocument()
    expect(
      within(getRow(wrapper, outboundCall)).getByLabelText('Outbound call'),
    ).toBeInTheDocument()
  })

  it('shows a known caller with their name', async () => {
    const wrapper = await renderTable({ items: [missedCall], totalCount: 1 })

    const row = getRow(wrapper, missedCall)

    expect(within(row).getByText('Franz Bauer')).toBeInTheDocument()
    expect(within(row).queryByText('Maybe')).not.toBeInTheDocument()
    expect(within(row).queryByText('Unknown')).not.toBeInTheDocument()
  })

  it('shows a possible caller matched by comment only with a maybe badge', async () => {
    const wrapper = await renderTable({ items: [callWithCommentMatch], totalCount: 1 })

    const row = getRow(wrapper, callWithCommentMatch)

    expect(within(row).getByText('Carla Weber')).toBeInTheDocument()
    expect(within(row).getByText('Maybe')).toBeInTheDocument()
  })

  it('shows the first of several possible callers with a counter for the rest', async () => {
    const wrapper = await renderTable({ items: [callWithPossibleCallers], totalCount: 1 })

    const row = getRow(wrapper, callWithPossibleCallers)

    expect(within(row).getByText('Anna Lena')).toBeInTheDocument()
    expect(within(row).getByText('+2')).toBeInTheDocument()
    expect(within(row).queryByText('Carla Weber')).not.toBeInTheDocument()
    expect(within(row).queryByText('Bob Smith')).not.toBeInTheDocument()

    // The second avatar of the stack stands for a match without a user, so it is decorative.
    expect(within(row).getAllByRole('img', { name: /^Avatar/ })).toHaveLength(1)
  })

  it('carries the maybe badge into the popover of a possible caller', async () => {
    // The popover query needs UserPolicy#show?, which comes with the ticket permissions.
    mockPermissions(['cti.agent', 'ticket.agent'])
    mockUserInfoForPopoverQuery({ user: { ...knownCustomer, fullname: 'Anna Lena' } })

    const wrapper = await renderTable({ items: [callWithPossibleCallers], totalCount: 1 })

    const row = getRow(wrapper, callWithPossibleCallers)

    await wrapper.events.hover(within(row).getByRole('img', { name: 'Avatar (Anna Lena)' }))

    const popover = await wrapper.findByRole('region')

    expect(await within(popover).findByText('Anna Lena')).toBeVisible()
    expect(within(popover).getByText('Maybe')).toBeVisible()
  })

  it('lists the remaining matches in a popover', async () => {
    const wrapper = await renderTable({ items: [callWithPossibleCallers], totalCount: 1 })

    await wrapper.events.hover(within(getRow(wrapper, callWithPossibleCallers)).getByText('+2'))

    const popover = await wrapper.findByRole('region')

    const matches = await within(popover).findAllByRole('listitem')

    expect(matches).toHaveLength(2)

    // A match without a user is not linked and shows a decorative avatar instead.
    expect(within(matches[0]).getByText('Carla Weber')).toBeInTheDocument()
    expect(within(matches[0]).queryByRole('link')).not.toBeInTheDocument()
    expect(within(matches[0]).queryByRole('img', { name: /^Avatar/ })).not.toBeInTheDocument()
    expect(within(matches[0]).getByText('Maybe')).toBeInTheDocument()

    expect(within(matches[1]).getByRole('link', { name: 'Bob Smith' })).toHaveAttribute(
      'href',
      '/users/4',
    )
    expect(within(matches[1]).getByRole('img', { name: 'Avatar (Bob Smith)' })).toBeInTheDocument()
    expect(within(matches[1]).getByText('Maybe')).toBeInTheDocument()

    expect(within(popover).queryByText('Anna Lena')).not.toBeInTheDocument()
  })

  it('shows the name the telephony backend sent for a side without a match', async () => {
    const wrapper = await renderTable({ items: [checkedCall], totalCount: 1 })

    const cells = within(getRow(wrapper, checkedCall)).getAllByRole('cell')

    expect(within(cells[1]).getByText('Bob Smith')).toBeInTheDocument()
    expect(within(cells[1]).queryByText('Maybe')).not.toBeInTheDocument()
  })

  it('falls back to the sent name instead of offering a new user', async () => {
    const wrapper = await renderTable({ items: [callFromDeletedUser], totalCount: 1 })

    const row = getRow(wrapper, callFromDeletedUser)

    expect(within(row).getByText('Carla Weber')).toBeInTheDocument()
    expect(within(row).queryByRole('button', { name: 'New user' })).not.toBeInTheDocument()
    expect(within(row).queryByRole('img', { name: 'Unknown caller' })).not.toBeInTheDocument()
  })

  it('offers creating a user for a caller without any match', async () => {
    const wrapper = await renderTable({ items: [callFromUnknown], totalCount: 1 })

    const row = getRow(wrapper, callFromUnknown)

    // Only the external party is offered, the called line of an inbound call is not.
    expect(within(row).getAllByRole('button', { name: 'New user' })).toHaveLength(1)
  })

  it('opens a new ticket for the created user, prefilled as its customer', async () => {
    mockUserCreateFlyoutQueries()
    mockUserAddMutation({
      userAdd: { user: { id: convertToGraphQLId('User', 42), internalId: 42 }, errors: null },
    })

    // The flyout container is keyed by the route it mounts on, so the router has to
    //   have settled on its start route before the table renders.
    const { unmount } = await renderTable()
    await getTestRouter().isReady()
    unmount()

    const wrapper = await renderTable({ items: [callFromUnknown], totalCount: 1 })

    await wrapper.events.click(
      within(getRow(wrapper, callFromUnknown)).getByRole('button', { name: 'New user' }),
    )

    const flyout = await wrapper.findByRole('complementary', { name: 'New user' })

    expect(await within(flyout).findByLabelText('Phone')).toHaveValue(callFromUnknown.fromPretty)

    await wrapper.events.click(within(flyout).getByRole('button', { name: 'Create' }))

    await waitForUserAddMutationCalls()

    expect(getTestRouter().push).toHaveBeenCalledWith({
      name: 'TicketCreate',
      query: { customer_id: 42 },
    })
  })

  // Opening or creating a user needs ticket or user permissions, which a phone agent may lack.
  describe('for a phone agent without ticket permissions', () => {
    beforeEach(() => {
      mockPermissions(['cti.agent'])
    })

    it('does not offer creating a user for a caller without any match', async () => {
      const wrapper = await renderTable({ items: [callFromUnknown], totalCount: 1 })

      const row = getRow(wrapper, callFromUnknown)

      expect(within(row).getByRole('img', { name: 'Unknown caller' })).toBeInTheDocument()
      expect(within(row).queryByRole('button', { name: 'New user' })).not.toBeInTheDocument()
    })

    it('lists the remaining matches as plain text', async () => {
      const wrapper = await renderTable({ items: [callWithPossibleCallers], totalCount: 1 })

      await wrapper.events.hover(within(getRow(wrapper, callWithPossibleCallers)).getByText('+2'))

      const popover = await wrapper.findByRole('region')

      expect(await within(popover).findByText('Bob Smith')).toBeInTheDocument()
      expect(within(popover).queryByRole('link')).not.toBeInTheDocument()
    })
  })

  it('renders phone numbers as callable links built from the raw number', async () => {
    const wrapper = await renderTable({ items: [missedCall], totalCount: 1 })

    const row = getRow(wrapper, missedCall)

    expect(within(row).getByRole('link', { name: '+49 30 609854180' })).toHaveAttribute(
      'href',
      'tel:4930609854180',
    )
    expect(within(row).getByRole('link', { name: '+49 30 609811111' })).toHaveAttribute(
      'href',
      'tel:4930609811111',
    )
  })

  it('formats the waiting time, the talking time and the time of the call', async () => {
    mockApplicationConfig({ pretty_date_format: 'absolute' })

    const wrapper = await renderTable({ items: [checkedCall], totalCount: 1 })

    const cells = within(getRow(wrapper, checkedCall)).getAllByRole('cell')

    expect(cells[3]).toHaveTextContent('00:20')
    expect(cells[4]).toHaveTextContent('00:45')
    expect(cells[5]).toHaveTextContent('2026-09-21 09:00')
  })

  it('renders the empty-list slot when there are no calls', async () => {
    const wrapper = renderComponent(CallerLogTable, {
      router: true,
      props: {
        tableId: 'caller-log',
        caption: 'Caller log',
        headers: callerLogHeaders,
        items: [],
        totalCount: 0,
        maxItems: 1000,
        loading: false,
        loadingNewPage: false,
      },
      slots: {
        'empty-list': '<div>Nothing here</div>',
      },
    })

    await waitForNextTick()

    expect(wrapper.queryByRole('table')).not.toBeInTheDocument()
    expect(wrapper.getByText('Nothing here')).toBeInTheDocument()
  })
})
