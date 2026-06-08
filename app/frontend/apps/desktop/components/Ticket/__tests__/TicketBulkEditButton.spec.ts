// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import renderComponent, { initializePiniaStore } from '#tests/support/components/renderComponent.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import '#tests/graphql/builders/mocks.ts'

import { EnumBulkUpdateStatusStatus } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import TicketBulkEditButton from '#desktop/components/Ticket/TicketBulkEditButton.vue'
import { useTicketBulkUpdateStore } from '#desktop/entities/user/current/stores/ticketBulkUpdate.ts'

describe('TicketBulkEditButton', () => {
  it('renders correctly depending on the current selection', async () => {
    mockPermissions(['ticket.agent'])

    const wrapper = renderComponent(TicketBulkEditButton, {
      props: {
        checkedTicketIds: new Set(),
        totalCount: 1,
      },
    })

    expect(wrapper.queryByRole('button', { name: 'Bulk actions' })).not.toBeInTheDocument()

    const checkedTicketIds = new Set([convertToGraphQLId('Ticket', 2)])

    await wrapper.rerender({
      checkedTicketIds,
    })

    expect(wrapper.getByRole('button', { name: 'Bulk actions' })).toBeInTheDocument()
    expect(wrapper.getByIconName('collection-play')).toBeInTheDocument()
  })

  it('does not render for customer user', () => {
    mockPermissions(['ticket.customer'])

    const wrapper = renderComponent(TicketBulkEditButton, {
      props: {
        checkedTicketIds: new Set(),
        totalCount: 1,
      },
    })

    expect(wrapper.queryByRole('button', { name: 'Bulk actions' })).not.toBeInTheDocument()
  })

  it('emits open flyout event', async () => {
    mockPermissions(['ticket.agent'])

    const checkedTicketIds = new Set([convertToGraphQLId('Ticket', 2)])

    const wrapper = renderComponent(TicketBulkEditButton, {
      props: {
        checkedTicketIds,
        totalCount: 1,
      },
    })

    await wrapper.events.click(wrapper.getByRole('button', { name: 'Bulk actions' }))

    expect(wrapper.emitted('open-flyout')).toBeTruthy()
  })

  it('renders information label only when bulk update is running', async () => {
    mockPermissions(['ticket.agent'])
    initializePiniaStore()

    const checkedTicketIds = new Set([convertToGraphQLId('Ticket', 2)])

    const wrapper = renderComponent(TicketBulkEditButton, {
      props: {
        checkedTicketIds,
        totalCount: 1,
      },
      store: true,
    })

    expect(wrapper.getByRole('button', { name: 'Bulk actions' })).not.toBeDisabled()
    expect(wrapper.queryByText('Bulk action in progress…')).not.toBeInTheDocument()

    const { setTicketBulkUpdateStatus } = useTicketBulkUpdateStore()

    setTicketBulkUpdateStatus({
      status: EnumBulkUpdateStatusStatus.Running,
      processedCount: 0,
      total: 5,
    })

    await waitForNextTick()

    expect(wrapper.queryByRole('button', { name: 'Bulk actions' })).not.toBeInTheDocument()
    expect(wrapper.getByText('Bulk action in progress…')).toBeInTheDocument()
  })

  it('does not render anything when the associated list is empty', async () => {
    mockPermissions(['ticket.agent'])
    initializePiniaStore()

    const checkedTicketIds = new Set([convertToGraphQLId('Ticket', 2)])

    const wrapper = renderComponent(TicketBulkEditButton, {
      props: {
        checkedTicketIds,
        totalCount: 0,
      },
      store: true,
    })

    expect(wrapper.queryByRole('button', { name: 'Bulk actions' })).not.toBeInTheDocument()
    expect(wrapper.queryByText('Bulk action in progress…')).not.toBeInTheDocument()

    const { setTicketBulkUpdateStatus } = useTicketBulkUpdateStore()

    setTicketBulkUpdateStatus({
      status: EnumBulkUpdateStatusStatus.Running,
      processedCount: 0,
      total: 5,
    })

    await waitForNextTick()

    expect(wrapper.queryByRole('button', { name: 'Bulk actions' })).not.toBeInTheDocument()
    expect(wrapper.queryByText('Bulk action in progress…')).not.toBeInTheDocument()
  })
})
