// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { within } from '@testing-library/vue'

import renderComponent from '#tests/support/components/renderComponent.ts'

import { mockFormUpdaterQuery } from '#shared/components/Form/graphql/queries/formUpdater.mocks.ts'
import { mockMacrosQuery } from '#shared/graphql/queries/macros.mocks.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import TicketBulkEditFlyout from '#desktop/components/Ticket/TicketBulkEditFlyout/TicketBulkEditFlyout.vue'
import {
  mockTicketUpdateBulkMutation,
  waitForTicketUpdateBulkMutationCalls,
} from '#desktop/entities/ticket/graphql/mutations/updateBulk.mocks.ts'

const ids = [convertToGraphQLId('Ticket', 1), convertToGraphQLId('Ticket', 2)]

const groupIds = [
  convertToGraphQLId('Group', 1),
  convertToGraphQLId('Group', 2),
]

const renderBulkEditFlyout = () => {
  mockFormUpdaterQuery({
    formUpdater: {
      fields: {
        group_id: {
          options: [
            {
              value: 2,
              label: 'test group',
            },
          ],
        },
        owner_id: {
          options: [
            {
              value: 3,
              label: 'Test Admin Agent',
            },
          ],
        },
        state_id: {
          options: [
            {
              value: 4,
              label: 'closed',
            },
          ],
        },
        pending_time: {
          show: false,
        },
      },
    },
  })

  return renderComponent(TicketBulkEditFlyout, {
    props: { ticketIds: ids, groupIds },
    form: true,
    router: true,
    global: {
      stubs: {
        teleport: true,
      },
    },
  })
}

describe('TicketBulkEditFlyout', () => {
  it('renders correctly', async () => {
    const wrapper = renderBulkEditFlyout()

    expect(wrapper.getByRole('heading', { level: 2 })).toHaveTextContent(
      'Tickets Bulk Edit',
    )

    expect(wrapper.getByIconName('collection-play')).toBeInTheDocument()

    expect(await wrapper.findByText('2 tickets selected')).toBeInTheDocument()
  })

  it('allows editing ticket attributes', async () => {
    const wrapper = renderBulkEditFlyout()
    const ticketState = await wrapper.findByLabelText('State')

    await wrapper.events.click(ticketState)

    expect(await wrapper.findByRole('menu')).toBeInTheDocument()

    await wrapper.events.click(wrapper.getByRole('option', { name: 'closed' }))

    await wrapper.events.click(wrapper.getByLabelText('Group'))

    await wrapper.events.click(
      wrapper.getByRole('option', { name: 'test group' }),
    )

    await wrapper.events.click(wrapper.getByRole('button', { name: 'Apply' }))

    const calls = await waitForTicketUpdateBulkMutationCalls()

    expect(calls.at(-1)?.variables).toEqual({
      input: {
        article: null,
        groupId: convertToGraphQLId('Group', 2),
        stateId: convertToGraphQLId('Ticket::State', 4),
      },
      ticketIds: ids,
    })
  })

  it('add a note to the tickets', async () => {
    const wrapper = renderBulkEditFlyout()

    const group = await wrapper.findByLabelText('Group')
    await wrapper.events.click(group)

    await wrapper.events.click(
      wrapper.getByRole('option', { name: 'test group' }),
    )

    await wrapper.events.click(wrapper.getByLabelText('Note'))

    await wrapper.events.click(wrapper.getByLabelText('Text'))
    await wrapper.events.type(
      wrapper.getByLabelText('Text'),
      'Test ticket text',
    )

    await wrapper.events.click(wrapper.getByRole('button', { name: 'Apply' }))

    const calls = await waitForTicketUpdateBulkMutationCalls()

    expect(calls.at(-1)?.variables).toEqual({
      input: {
        article: {
          body: 'Test ticket text',
          internal: false,
          contentType: 'text/html',
          type: 'note',
        },
        groupId: convertToGraphQLId('Group', 2),
      },
      ticketIds: ids,
    })
  })

  it('executes macro on tickets', async () => {
    mockMacrosQuery({
      macros: [
        {
          name: 'test macro',
          id: convertToGraphQLId('Macro', 1),
          uxFlowNextUp: 'next_task',
        },
      ],
    })

    const wrapper = renderBulkEditFlyout()

    await wrapper.events.click(
      wrapper.getByRole('button', { name: 'Context menu' }),
    )

    const menu = await wrapper.findByRole('menu')

    expect(
      within(menu).getByRole('heading', { name: 'Macros' }),
    ).toBeInTheDocument()

    await wrapper.events.click(
      within(menu).getByRole('button', { name: 'test macro' }),
    )

    const calls = await waitForTicketUpdateBulkMutationCalls()

    expect(calls.at(-1)?.variables).toEqual({
      input: {
        article: null,
      },
      macroId: convertToGraphQLId('Macro', 1),
      ticketIds: ids,
    })
  })

  describe('errors', () => {
    it('shows error when ticket fails to save', async () => {
      mockTicketUpdateBulkMutation({
        ticketUpdateBulk: {
          success: false,
          errors: [
            {
              message: "Missing required value for field 'example'!",
              failedTicket: {
                id: ids[0],
                number: '12345',
                title: 'Test Ticket',
              },
            },
          ],
        },
      })

      const wrapper = renderBulkEditFlyout()

      await wrapper.findByLabelText('State')

      await wrapper.events.click(wrapper.getByRole('button', { name: 'Apply' }))

      expect(
        await wrapper.findByText(
          "Ticket failed to save: Ticket#12345 - Test Ticket (Reason: Missing required value for field 'example'!)",
        ),
      ).toBeInTheDocument()
    })
  })
})
