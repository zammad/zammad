// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { waitFor } from '@testing-library/vue'
import { TicketMergeDocument } from '@shared/entities/ticket/graphql/mutations/merge.api'
import {
  NotificationTypes,
  useNotifications,
} from '@shared/components/CommonNotifications'
import { useDialog } from '@shared/composables/useDialog'
import { convertToGraphQLId } from '@shared/graphql/utils'
import { renderComponent } from '@tests/support/components'
import { getTestRouter } from '@tests/support/components/renderComponent'
import { mockGraphQLApi } from '@tests/support/mock-graphql-api'
import { mockPermissions } from '@tests/support/mock-permissions'
import { nullableMock, waitUntil } from '@tests/support/utils'
import { defaultTicket } from '@mobile/pages/ticket/__tests__/mocks/detail-view'
import { AutocompleteSearchMergeTicketDocument } from '../../../graphql/queries/autocompleteSearchMergeTicket.api'
import TicketActionsDialog from '../TicketActionsDialog.vue'

const { notify } = useNotifications()

beforeAll(async () => {
  await import(
    '@shared/components/Form/fields/FieldAutoComplete/FieldAutoCompleteInputDialog.vue'
  )
})

const { ticket: currentTicket } = defaultTicket()

describe('actions that you can do with a ticket, when clicked on 3 dots', () => {
  it("don't see 'merge' tickets, if have no rights", async () => {
    mockPermissions([])

    const view = renderComponent(TicketActionsDialog, {
      props: {
        name: 'ticket-actions',
        ticket: { ...currentTicket, subscribed: null },
      },
      dialog: true,
      form: true,
      router: true,
    })
    expect(
      view.queryByRole('button', { name: 'Merge tickets' }),
    ).not.toBeInTheDocument()
  })

  it("don't see 'subscribe' button, if have no rights", () => {
    mockPermissions([])

    const view = renderComponent(TicketActionsDialog, {
      props: {
        name: 'ticket-actions',
        ticket: { ...currentTicket, subscribed: null },
      },
      dialog: true,
      form: true,
      router: true,
    })
    expect(
      view.queryByRole('button', { name: 'Subscribe' }),
    ).not.toBeInTheDocument()
    expect(
      view.queryByRole('button', { name: 'Unsubscribe' }),
    ).not.toBeInTheDocument()
  })

  it('shows an error, if no ticket is selected and user is trying to merge', async () => {
    mockPermissions(['ticket.agent'])

    const view = renderComponent(TicketActionsDialog, {
      props: {
        name: 'ticket-actions',
        ticket: currentTicket,
      },
      dialog: true,
      form: true,
      router: true,
    })

    const mergeButton = view.getByRole('button', { name: 'Merge tickets' })
    await view.events.click(mergeButton)

    await waitUntil(() => view.queryByRole('dialog', { name: 'Find a ticket' }))

    await view.events.click(view.getByRole('button', { name: 'Confirm merge' }))

    expect(notify).toHaveBeenCalledWith({
      type: NotificationTypes.Error,
      message: 'Please select a ticket to merge into.',
    })
  })

  it('can merge tickets, when have rights', async () => {
    mockPermissions(['ticket.agent'])

    useDialog({
      name: 'ticket-actions',
      component: () => Promise.resolve({}),
    })

    const currentTicketId = convertToGraphQLId('Ticket', 1)
    const targetTicketId = convertToGraphQLId('Ticket', 5)
    const targetTicket = {
      ...defaultTicket().ticket,
      id: targetTicketId,
      number: '90005',
      internalId: 5,
    }

    const searchMock = mockGraphQLApi(
      AutocompleteSearchMergeTicketDocument,
    ).willResolve({
      autocompleteSearchMergeTicket: [
        nullableMock({
          value: targetTicketId,
          ticket: targetTicket,
          label: 'Ticket #1',
        }),
      ],
    })

    const view = renderComponent(TicketActionsDialog, {
      props: {
        name: 'ticket-actions',
        ticket: currentTicket,
      },
      dialog: true,
      form: true,
      router: true,
      confirmation: true,
    })

    const mergeButton = view.getByRole('button', { name: 'Merge tickets' })
    expect(mergeButton).toBeInTheDocument()

    await view.events.click(mergeButton)

    expect(
      view.findByRole('dialog', { name: 'Find a ticket' }),
    ).resolves.toBeInTheDocument()

    await view.events.type(view.getByRole('searchbox'), 'Ticket')

    await waitUntil(() => searchMock.calls.resolve)

    const mergeMock = mockGraphQLApi(TicketMergeDocument).willResolve({
      ticketMerge: {
        errors: null,
      },
    })

    const option = view.getByRole('option', { name: 'Ticket #1' })
    expect(option).toBeInTheDocument()

    await view.events.click(option)
    await view.events.click(view.getByRole('button', { name: 'Confirm merge' }))
    await view.events.click(view.getByRole('button', { name: 'OK' }))

    await waitUntil(() => mergeMock.calls.resolve)

    expect(mergeMock.spies.resolve).toHaveBeenCalledWith({
      sourceTicketId: currentTicketId,
      targetTicketId,
    })

    expect(getTestRouter().currentRoute.value.path).toBe(`/tickets/5`)
  })

  it("don't see 'change customer', if have no rights", async () => {
    mockPermissions([])

    const view = renderComponent(TicketActionsDialog, {
      props: {
        name: 'ticket-actions',
        ticket: currentTicket,
      },
      dialog: true,
      form: true,
      router: true,
    })

    expect(
      view.queryByRole('button', { name: 'Change customer' }),
    ).not.toBeInTheDocument()
  })

  it('can open change customer, when have rights (and close without confirmation)', async () => {
    mockPermissions(['ticket.agent'])

    const view = renderComponent(TicketActionsDialog, {
      props: {
        name: 'ticket-actions',
        ticket: currentTicket,
      },
      dialog: true,
      form: true,
      router: true,
    })

    const customerChangeButton = view.getByText('Change customer')

    await view.events.click(customerChangeButton)

    await waitFor(() => {
      expect(
        view.queryByRole('dialog', { name: 'Change customer' }),
      ).toBeInTheDocument()
    })

    await view.events.click(view.getByRole('button', { name: 'Cancel' }))

    await waitFor(() => {
      expect(
        view.queryByRole('dialog', { name: 'Change customer' }),
      ).not.toBeInTheDocument()
    })
  })
})
