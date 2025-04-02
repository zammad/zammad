// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import renderComponent from '#tests/support/components/renderComponent.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import TicketBulkEditButton from '#desktop/components/Ticket/TicketBulkEditButton.vue'

describe('TicketBulkEditButton', () => {
  it('render correctly without any id', async () => {
    mockPermissions(['ticket.agent'])

    const wrapper = renderComponent(TicketBulkEditButton, {
      props: {
        checkedTicketIds: new Set(),
      },
    })

    expect(
      wrapper.queryByRole('button', { name: 'Bulk Actions' }),
    ).not.toBeInTheDocument()

    const checkedTicketIds = new Set([convertToGraphQLId('Ticket', 2)])

    await wrapper.rerender({
      checkedTicketIds,
    })

    expect(
      wrapper.getByRole('button', { name: 'Bulk Actions' }),
    ).toHaveTextContent('Bulk Actions')
    expect(wrapper.getByIconName('collection-play')).toBeInTheDocument()
  })

  it("doesn't render for customer user", () => {
    mockPermissions(['ticket.customer'])

    const wrapper = renderComponent(TicketBulkEditButton, {
      props: {
        checkedTicketIds: new Set(),
      },
    })

    expect(
      wrapper.queryByTestId('ticket-bulk-edit-button'),
    ).not.toBeInTheDocument()
  })

  it('emits open flyout event', async () => {
    mockPermissions(['ticket.agent'])

    const checkedTicketIds = new Set([convertToGraphQLId('Ticket', 2)])

    const wrapper = renderComponent(TicketBulkEditButton, {
      props: {
        checkedTicketIds,
      },
    })

    await wrapper.events.click(wrapper.getByTestId('ticket-bulk-edit-button'))

    expect(wrapper.emitted('open-flyout')).toBeTruthy()
  })
})
