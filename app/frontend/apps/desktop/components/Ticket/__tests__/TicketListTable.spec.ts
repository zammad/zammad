// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { within } from '@testing-library/vue'

import '#tests/graphql/builders/mocks.ts'
import { renderComponent, type ExtendedMountingOptions } from '#tests/support/components/index.ts'
import { getTestRouter } from '#tests/support/components/renderComponent.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'
import { mockRouterHooks } from '#tests/support/mock-vue-router.ts'
import { nullableMock, waitForNextTick } from '#tests/support/utils.ts'

import type { TicketByList } from '#shared/entities/ticket/types.ts'
import { EnumTicketStateColorCode } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import { SYSTEM_USER_ID } from '#shared/utils/constants.ts'

import type { ListTableProps } from '#desktop/components/CommonTable/types.ts'

import TicketListTable from '../TicketListTable.vue'
import {
  mockTicketInfoForPopoverQuery,
  waitForTicketInfoForPopoverQueryCalls,
} from '../TicketPopoverWithTrigger/graphql/queries/ticketInfoForPopover.mocks.ts'

mockRouterHooks()

const renderListTable = async (
  props: ListTableProps<TicketByList>,
  options: ExtendedMountingOptions<ListTableProps<TicketByList>> = {
    form: true,
  },
) => {
  const wrapper = renderComponent(TicketListTable, {
    router: true,
    ...options,
    props: {
      ...props,
    },
  })

  await waitForNextTick()

  return wrapper
}

const tableHeaders = ['title', 'owner', 'state', 'stateIcon', 'priority']

const tableItems: TicketByList[] = [
  nullableMock<TicketByList>({
    __typename: 'Ticket',
    id: convertToGraphQLId('Ticket', 1),
    title: 'Dummy ticket',
    owner: {
      __typename: 'User',
      id: convertToGraphQLId('User', 1),
      fullname: 'Agent 1 Test',
    },
    state: {
      __typename: 'TicketState',
      id: convertToGraphQLId('TicketState', 1),
      name: 'open',
      stateType: {
        __typename: 'TicketStateType',
        id: convertToGraphQLId('TicketStateType', 1),
        name: 'open',
      },
    },
    priority: {
      __typename: 'TicketPriority',
      id: convertToGraphQLId('TicketPriority', 3),
      name: '3 high',
      uiColor: null,
    },
    createdAt: '2021-01-01T12:00:00Z',
    internalId: 1,
    number: '31001',
    updatedAt: '',
    stateColorCode: EnumTicketStateColorCode.Closed,
    customer: {
      __typename: 'User',
      id: '',
      fullname: undefined,
    },
    group: {
      __typename: 'Group',
      id: '',
      name: undefined,
    },
    policy: {
      __typename: 'PolicyTicket',
      update: false,
    },
  }),
]

describe('TicketListTable', () => {
  it('displays the ticket list', async () => {
    const wrapper = await renderListTable({
      headers: tableHeaders,
      items: tableItems,
      totalCount: 100,
      caption: 'Table caption',
      tableId: 'ticket-list-table',
      maxItems: 1000,
      loading: false,
      loadingNewPage: false,
    })

    expect(wrapper.getByText('Title')).toBeInTheDocument()
    expect(wrapper.getByText('Owner')).toBeInTheDocument()
    expect(wrapper.getByText('State')).toBeInTheDocument()

    expect(wrapper.getByText('Dummy ticket')).toBeInTheDocument()
    expect(wrapper.getByText('Agent 1 Test')).toBeInTheDocument()
    expect(wrapper.getByText('open')).toBeInTheDocument()
    expect(wrapper.getByText('3 high')).toBeInTheDocument()
  })

  it('displays a ticket of the system customer as having no customer', async () => {
    const wrapper = await renderListTable({
      headers: ['title', 'customer'],
      items: [
        {
          ...tableItems[0],
          customer: {
            __typename: 'User',
            id: SYSTEM_USER_ID,
            fullname: 'System',
          },
        },
      ],
      totalCount: 1,
      caption: 'Table caption',
      tableId: 'ticket-list-table',
      maxItems: 1000,
      loading: false,
      loadingNewPage: false,
    })

    const customerCell = wrapper.getByText('-')

    expect(customerCell.closest('[aria-controls]')).toBeNull()
    expect(wrapper.queryByText('System')).not.toBeInTheDocument()
  })

  describe('Ai Agent', () => {
    it('displays that indicator that agent is running', async () => {
      const wrapper = await renderListTable({
        headers: tableHeaders,
        items: [{ ...tableItems[0], aiAgentRunning: true }],
        totalCount: 100,
        caption: 'Table caption',
        tableId: 'ticket-list-table',
        maxItems: 1000,
        loading: false,
        loadingNewPage: false,
      })

      expect(
        wrapper.getByRole('status', { name: 'Currently processing this ticket…' }),
      ).toBeInTheDocument()
    })
  })

  describe('Ticket popover', () => {
    const renderPopoverListTable = () =>
      renderListTable({
        headers: ['number', 'title', 'owner'],
        items: tableItems,
        totalCount: 1,
        caption: 'Table caption',
        tableId: 'ticket-list-table',
        maxItems: 1000,
        loading: false,
        loadingNewPage: false,
      })

    beforeEach(() => {
      mockApplicationConfig({ ticket_hook: 'Ticket#' })

      mockTicketInfoForPopoverQuery({
        ticket: {
          id: tableItems[0].id,
          internalId: tableItems[0].internalId,
          number: tableItems[0].number,
          title: tableItems[0].title,
          owner: {
            id: convertToGraphQLId('User', 3),
            fullname: 'Agent 1 Test',
          },
          customer: {
            id: convertToGraphQLId('User', 2),
            fullname: 'Nicole Braun',
          },
          group: {
            id: convertToGraphQLId('Group', 1),
            name: 'Users',
          },
          priority: {
            id: convertToGraphQLId('TicketPriority', 3),
            name: '3 high',
          },
        },
      })
    })

    it.each([
      { column: 'title', linkName: 'Dummy ticket' },
      { column: 'number', linkName: '31001' },
    ])('shows the ticket details when hovering the $column', async ({ linkName }) => {
      mockPermissions(['ticket.agent'])

      const wrapper = await renderPopoverListTable()

      const link = wrapper.getByRole('link', { name: linkName })

      expect(link.querySelector('[data-tooltip]')).not.toBeInTheDocument()

      await wrapper.events.hover(link)

      const calls = await waitForTicketInfoForPopoverQueryCalls()

      expect(calls.at(-1)?.variables).toEqual({
        ticketId: tableItems[0].id,
        withContent: true,
      })

      const popover = await wrapper.findByRole('region')

      expect(within(popover).getByText('Dummy ticket')).toBeVisible()
      expect(within(popover).getByText('Ticket#31001')).toBeVisible()

      expect(within(popover).queryByText('Users')).not.toBeInTheDocument()
      expect(within(popover).queryByText('3 high')).not.toBeInTheDocument()
    })

    it.each([
      {
        action: 'clicking',
        activate: (wrapper: Awaited<ReturnType<typeof renderPopoverListTable>>) =>
          wrapper.events.click(wrapper.getByRole('link', { name: 'Dummy ticket' })),
      },
      {
        action: 'pressing Enter on',
        activate: async (wrapper: Awaited<ReturnType<typeof renderPopoverListTable>>) => {
          wrapper.getByRole('link', { name: 'Dummy ticket' }).focus()
          await wrapper.events.keyboard('{Enter}')
        },
      },
    ])('navigates once when $action the title', async ({ activate }) => {
      mockPermissions(['ticket.agent'])

      const wrapper = await renderPopoverListTable()

      await getTestRouter().isReady()

      const pushSpy = vi.spyOn(getTestRouter(), 'push')

      await activate(wrapper)

      expect(pushSpy).toHaveBeenCalledTimes(1)
      expect(pushSpy).toHaveBeenCalledWith('/tickets/1')
    })

    it('keeps a plain link without a popover for customers', async () => {
      mockPermissions(['ticket.customer'])

      const wrapper = await renderPopoverListTable()

      const link = wrapper.getByRole('link', { name: 'Dummy ticket' })

      expect(link).toHaveAttribute('href', '/desktop/tickets/1')
      expect(link).not.toHaveAttribute('aria-controls')
      expect(link).toHaveAttribute('data-tooltip', 'truncate')
    })
  })
})
