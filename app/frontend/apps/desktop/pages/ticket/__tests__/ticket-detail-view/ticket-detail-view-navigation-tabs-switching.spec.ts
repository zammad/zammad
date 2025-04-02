// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { within, waitFor } from '@testing-library/vue'
import { beforeEach } from 'vitest'

import ticketCustomerObjectAttributes from '#tests/graphql/factories/fixtures/ticket-customer-object-attributes.ts'
import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import { mockFormUpdaterQuery } from '#shared/components/Form/graphql/queries/formUpdater.mocks.ts'
import { mockObjectManagerFrontendAttributesQuery } from '#shared/entities/object-attributes/graphql/queries/objectManagerFrontendAttributes.mocks.ts'
import { mockTicketQuery } from '#shared/entities/ticket/graphql/queries/ticket.mocks.ts'
import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'
import {
  EnumTaskbarEntity,
  EnumTaskbarEntityAccess,
} from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { mockUserCurrentTaskbarItemListQuery } from '#desktop/entities/user/current/graphql/queries/userCurrentTaskbarItemList.mocks.ts'
import { mockTicketChecklistQuery } from '#desktop/pages/ticket/graphql/queries/ticketChecklist.mocks.ts'

const getTaskbarEntityKey = (internalTicketId: number) =>
  `Ticket-${internalTicketId}`

describe('Ticket detail view multi tabs switching', () => {
  const ticket = createDummyTicket({ number: '53001' })
  const secondTicket = createDummyTicket({
    ticketId: '42',
    number: '53042',
    title: 'Example Ticket',
    state: {
      id: convertToGraphQLId('Ticket::State', 4),
      name: 'closed',
      stateType: {
        id: convertToGraphQLId('Ticket::StateType', 5),
        name: 'closed',
      },
    },
  })

  beforeEach(() => {
    mockPermissions(['ticket.agent'])
    mockObjectManagerFrontendAttributesQuery({
      objectManagerFrontendAttributes: ticketCustomerObjectAttributes(),
    })

    mockUserCurrentTaskbarItemListQuery({
      userCurrentTaskbarItemList: [
        {
          id: convertToGraphQLId('Taskbar', 999),
          key: getTaskbarEntityKey(ticket.internalId),
          callback: EnumTaskbarEntity.TicketZoom,
          entityAccess: EnumTaskbarEntityAccess.Granted,
          entity: {
            id: convertToGraphQLId('Ticket', ticket.internalId),
            internalId: ticket.internalId,
            number: ticket.number,
            title: ticket.title,
            stateColorCode: ticket.stateColorCode,
            state: ticket.state,
          },
        },
        {
          id: convertToGraphQLId('Taskbar', 888),
          key: getTaskbarEntityKey(secondTicket.internalId),
          callback: EnumTaskbarEntity.TicketZoom,
          entityAccess: EnumTaskbarEntityAccess.Granted,
          entity: {
            id: convertToGraphQLId('Ticket', secondTicket.internalId),
            internalId: secondTicket.internalId,
            number: secondTicket.number,
            title: secondTicket.title,
            stateColorCode: secondTicket.stateColorCode,
            state: secondTicket.state,
          },
        },
      ],
    })

    mockFormUpdaterQuery({
      formUpdater: {
        fields: {
          state_id: {
            options: [
              {
                value: 4,
                label: 'closed',
              },
              {
                value: 2,
                label: 'open',
              },
            ],
          },
        },
        flags: {
          newArticlePresent: false,
        },
      },
    })

    mockTicketQuery({
      ticket,
    })
  })

  it('remembers collapsed states if user returns to tab', async () => {
    const view = await visitView('/tickets/1')

    let contentSidebar = await view.findByLabelText('Content sidebar')
    let collapsableHeaderButtons = within(contentSidebar).getByTestId(
      'controls-ticket-attributes',
    )

    await view.events.click(view.getByTestId('controls-ticket-attributes'))

    expect(collapsableHeaderButtons).toHaveAttribute('aria-expanded', 'false')

    let collapsedSection =
      within(contentSidebar).getByTestId('ticket-attributes')

    expect(collapsedSection).toHaveStyle('display: none')

    mockTicketQuery({
      ticket: secondTicket,
    })

    await view.events.click(
      await view.findByRole('link', {
        name: `Ticket#${secondTicket.number} - ${secondTicket.title}`,
      }),
    )

    expect(view.getByLabelText('State')).toHaveTextContent('closed')

    contentSidebar = await view.findByLabelText('Content sidebar')
    collapsableHeaderButtons = within(contentSidebar).getByTestId(
      'controls-ticket-attributes',
    )
    expect(collapsableHeaderButtons).toHaveAttribute('aria-expanded', 'true')

    collapsedSection = within(contentSidebar).getByTestId('ticket-attributes')
    expect(collapsedSection).toHaveStyle('display: block')

    await view.events.click(
      await view.findByRole('link', {
        name: `Ticket#${ticket.number} - ${ticket.title}`,
      }),
    )

    expect(view.getByLabelText('State')).toHaveTextContent('open')

    contentSidebar = await view.findByLabelText('Content sidebar')
    collapsableHeaderButtons = within(contentSidebar).getByTestId(
      'controls-ticket-attributes',
    )
    expect(collapsableHeaderButtons).toHaveAttribute('aria-expanded', 'false')

    collapsedSection = within(contentSidebar).getByTestId('ticket-attributes')
    expect(collapsedSection).toHaveStyle('display: none')
  })

  it.todo('preserves the flyout from the previous taskbar tab', async () => {
    // Current route is not updating when clicking on the link
    // Initial condition of isActive within CommonFlyout is not met

    const view = await visitView('/tickets/1')

    const sidebar = await view.findByLabelText('Content sidebar')

    await view.events.click(
      within(sidebar).getByRole('button', { name: 'Action menu button' }),
    )

    await view.events.click(
      await view.findByRole('button', { name: 'Change customer' }),
    )

    const flyoutForFirstTicket = await view.findByRole('complementary', {
      name: 'Change Customer',
    })

    expect(flyoutForFirstTicket).toBeInTheDocument()

    await view.events.click(
      await view.findByRole('link', {
        name: `Ticket#${secondTicket.number} - ${secondTicket.title}`,
      }),
    )

    await waitForNextTick()

    await waitFor(() => expect(flyoutForFirstTicket).not.toBeVisible())

    await view.events.click(
      await view.findByRole('link', {
        name: `Ticket#${secondTicket.number} - ${secondTicket.title}`,
      }),
    )
  })

  it.todo(
    'preserves the conformation dialog from the previous taskbar tab',
    async () => {
      // Current route is not updating when clicking on the link
      // Initial condition of isActive within CommonDialog is not met

      mockTicketChecklistQuery({
        ticketChecklist: {
          name: 'Ticket Checklist',
          id: convertToGraphQLId('Ticket::Checklist', 1),
          items: [],
        },
      })

      await mockApplicationConfig({
        checklist: true,
      })

      const view = await visitView('/tickets/1')

      await view.events.click(view.getByRole('button', { name: 'Checklist' }))

      const sidebar = await view.findByLabelText('Content sidebar')

      await view.events.click(
        within(sidebar).getByRole('button', { name: 'Action menu button' }),
      )

      await view.events.click(
        view.getByRole('button', { name: 'Remove checklist' }),
      )

      const firstTicketDialog = await view.findByRole('dialog', {
        name: 'Delete Object',
      })

      expect(firstTicketDialog).toBeInTheDocument()

      await view.events.click(
        await view.findByRole('link', {
          name: `Ticket#${secondTicket.number} - ${secondTicket.title}`,
        }),
      )

      await waitForNextTick()
      // :TODO Router does not work as expected it does not update

      await waitFor(() => expect(firstTicketDialog).not.toBeInTheDocument())

      await view.events.click(
        await view.findByRole('link', {
          name: `Ticket#${ticket.number} - ${ticket.title}`,
        }),
      )

      await waitFor(() => expect(firstTicketDialog).toBeInTheDocument())
    },
  )

  it('remembers the sidebar tab selection of the current taskbar tab', async () => {
    const view = await visitView('/tickets/1')

    const customerSidebarTab = await view.findByRole('button', {
      name: 'Customer',
    })

    await view.events.click(customerSidebarTab)

    /**
     * @url https://github.com/zammad/coordination-desktop-view/issues/329?issue=zammad%7Ccoordination-desktop-view%7C330
     * Sidebar tabs should be a tab rather than a button
     * */

    await waitFor(() =>
      expect(customerSidebarTab).toHaveClass('outline-blue-800'),
    )

    await view.events.click(
      await view.findByRole('link', {
        name: `Ticket#${secondTicket.number} - ${secondTicket.title}`,
      }),
    )

    await waitForNextTick()

    await waitFor(() =>
      expect(view.getByRole('button', { name: 'Ticket' })).toHaveClass(
        'outline-blue-800',
      ),
    )

    await view.events.click(
      await view.findByRole('link', {
        name: `Ticket#${ticket.number} - ${ticket.title}`,
      }),
    )

    await waitFor(() =>
      expect(customerSidebarTab).toHaveClass('outline-blue-800'),
    )

    expect(view.getByRole('button', { name: 'Ticket' })).not.toHaveClass(
      'outline-blue-800',
    )
  })
})
