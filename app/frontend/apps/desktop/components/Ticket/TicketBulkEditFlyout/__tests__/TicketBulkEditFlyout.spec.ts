// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { within } from '@testing-library/vue'

import renderComponent, { initializePiniaStore } from '#tests/support/components/renderComponent.ts'

import {
  mockFormUpdaterQuery,
  waitForFormUpdaterQueryCalls,
} from '#shared/components/Form/graphql/queries/formUpdater.mocks.ts'
import { mockMacrosQuery } from '#shared/graphql/queries/macros.mocks.ts'
import { EnumBulkUpdateStatusStatus } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import TicketBulkEditFlyout from '#desktop/components/Ticket/TicketBulkEditFlyout/TicketBulkEditFlyout.vue'
import {
  mockTicketUpdateBulkMutation,
  waitForTicketUpdateBulkMutationCalls,
} from '#desktop/entities/ticket/graphql/mutations/updateBulk.mocks.ts'
import { useTicketBulkUpdateStore } from '#desktop/entities/user/current/stores/ticketBulkUpdate.ts'

const ids = [convertToGraphQLId('Ticket', 1), convertToGraphQLId('Ticket', 2)]

const macrosSelector = {
  entityIds: [convertToGraphQLId('Group', 1), convertToGraphQLId('Group', 2)],
}

const renderBulkEditFlyout = () => {
  initializePiniaStore()

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
    props: {
      currentSelectedTicketCount: ids.length,
      bulkCount: 0,
      bulkSelector: {
        entityIds: ids,
      },
      macrosSelector,
    },
    form: true,
    router: true,
    store: true,
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

    expect(wrapper.getByRole('heading', { level: 2 })).toHaveTextContent('Tickets bulk edit')

    expect(wrapper.getByIconName('collection-play')).toBeInTheDocument()

    expect(await wrapper.findByText('2 ticket(s) selected')).toBeInTheDocument()
  })

  it('includes ticket IDs in form updater request', async () => {
    const wrapper = renderBulkEditFlyout()

    await wrapper.findByText('2 ticket(s) selected')

    const calls = await waitForFormUpdaterQueryCalls()

    expect(calls.at(-1)?.variables).toMatchObject({
      meta: {
        additionalData: {
          entityIds: [convertToGraphQLId('Ticket', 1), convertToGraphQLId('Ticket', 2)],
        },
      },
    })
  })

  it('allows editing ticket attributes', async () => {
    const wrapper = renderBulkEditFlyout()
    const ticketState = await wrapper.findByLabelText('State')

    await wrapper.events.click(ticketState)

    expect(await wrapper.findByRole('menu')).toBeInTheDocument()

    await wrapper.events.click(wrapper.getByRole('option', { name: 'closed' }))

    await wrapper.events.click(wrapper.getByLabelText('Group'))

    await wrapper.events.click(wrapper.getByRole('option', { name: 'test group' }))

    await wrapper.events.click(wrapper.getByRole('button', { name: 'Apply' }))

    const calls = await waitForTicketUpdateBulkMutationCalls()

    expect(calls.at(-1)?.variables).toMatchObject({
      perform: {
        input: {
          groupId: convertToGraphQLId('Group', 2),
          stateId: convertToGraphQLId('Ticket::State', 4),
        },
      },
      selector: {
        entityIds: ids,
      },
    })
  })

  it('add a note to the tickets', async () => {
    const wrapper = renderBulkEditFlyout()

    const group = await wrapper.findByLabelText('Group')
    await wrapper.events.click(group)

    await wrapper.events.click(wrapper.getByRole('option', { name: 'test group' }))

    await wrapper.events.click(wrapper.getByLabelText('Note'))

    await wrapper.events.click(await wrapper.findByLabelText('Text'))
    await wrapper.events.type(wrapper.getByLabelText('Text'), 'Test ticket text')

    await wrapper.events.click(wrapper.getByRole('button', { name: 'Apply' }))

    const calls = await waitForTicketUpdateBulkMutationCalls()

    expect(calls.at(-1)?.variables).toEqual({
      perform: {
        input: {
          article: {
            body: 'Test ticket text',
            internal: false,
            contentType: 'text/html',
            type: 'note',
          },
          groupId: convertToGraphQLId('Group', 2),
        },
      },
      selector: {
        entityIds: ids,
      },
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

    await wrapper.events.click(wrapper.getByRole('button', { name: 'Context menu' }))

    const menu = await wrapper.findByRole('menu')

    expect(within(menu).getByRole('heading', { name: 'Macros' })).toBeInTheDocument()

    await wrapper.events.click(within(menu).getByRole('button', { name: 'test macro' }))

    const calls = await waitForTicketUpdateBulkMutationCalls()

    expect(calls.at(-1)?.variables).toEqual({
      perform: {
        input: {
          article: null,
        },
        macroId: convertToGraphQLId('Macro', 1),
      },
      selector: {
        entityIds: ids,
      },
    })
  })

  describe('errors', () => {
    it('shows success and error alerts when some tickets fail to save', async () => {
      mockTicketUpdateBulkMutation({
        ticketUpdateBulk: {
          async: false,
          failedCount: 1,
          total: 100,
          invalidTicketIds: [ids[0]],
        },
      })

      const wrapper = renderBulkEditFlyout()

      await wrapper.findByLabelText('State')

      await wrapper.events.click(wrapper.getByRole('button', { name: 'Apply' }))

      expect(
        await wrapper.findByText('Bulk action successful for 99 ticket(s).'),
      ).toBeInTheDocument()

      expect(
        await wrapper.findByText(
          'Bulk action failed for 1 ticket(s). Check attribute values and try again.',
        ),
      ).toBeInTheDocument()
    })

    it('shows error when another bulk update is already running', async () => {
      const wrapper = renderBulkEditFlyout()

      await wrapper.findByLabelText('State')

      useTicketBulkUpdateStore().setTicketBulkUpdateStatus({
        status: EnumBulkUpdateStatusStatus.Running,
        processedCount: 0,
        total: 5,
      })

      await wrapper.events.click(wrapper.getByRole('button', { name: 'Apply' }))

      expect(
        await wrapper.findByText(
          'Another bulk update is currently in progress. Please wait until it is finished before starting a new one.',
        ),
      ).toBeInTheDocument()
    })

    it('shows only error when all tickets fail to save', async () => {
      mockTicketUpdateBulkMutation({
        ticketUpdateBulk: {
          async: false,
          failedCount: 2,
          total: 2,
          invalidTicketIds: ids,
        },
      })

      const wrapper = renderBulkEditFlyout()

      await wrapper.findByLabelText('State')

      await wrapper.events.click(wrapper.getByRole('button', { name: 'Apply' }))

      expect(
        await wrapper.findByText(
          'Bulk action failed for 2 ticket(s). Check attribute values and try again.',
        ),
      ).toBeInTheDocument()

      expect(wrapper.queryByText(/Bulk action successful/)).not.toBeInTheDocument()
    })
  })

  it('handles successful bulk update without failures', async () => {
    mockTicketUpdateBulkMutation({
      ticketUpdateBulk: {
        async: false,
        failedCount: 0,
        total: 2,
        invalidTicketIds: [],
      },
    })

    const wrapper = renderBulkEditFlyout()

    const ticketState = await wrapper.findByLabelText('State')

    await wrapper.events.click(ticketState)

    await wrapper.events.click(wrapper.getByRole('option', { name: 'closed' }))

    await wrapper.events.click(wrapper.getByRole('button', { name: 'Apply' }))

    const calls = await waitForTicketUpdateBulkMutationCalls()

    expect(calls.at(-1)?.variables).toMatchObject({
      perform: {
        input: {
          stateId: convertToGraphQLId('Ticket::State', 4),
        },
      },
      selector: {
        entityIds: ids,
      },
    })
  })

  it('handles async bulk update', async () => {
    mockTicketUpdateBulkMutation({
      ticketUpdateBulk: {
        async: true,
        total: 100,
        failedCount: 0,
        invalidTicketIds: [],
      },
    })

    const wrapper = renderBulkEditFlyout()

    const store = useTicketBulkUpdateStore()
    const setStatusSpy = vi.spyOn(store, 'setTicketBulkUpdateStatus')

    const ticketState = await wrapper.findByLabelText('State')

    await wrapper.events.click(ticketState)

    await wrapper.events.click(wrapper.getByRole('option', { name: 'closed' }))

    await wrapper.events.click(wrapper.getByRole('button', { name: 'Apply' }))

    await waitForTicketUpdateBulkMutationCalls()

    expect(setStatusSpy).toHaveBeenCalledWith({
      status: EnumBulkUpdateStatusStatus.Pending,
      processedCount: 0,
      total: 100,
    })
  })

  it('toggles note section', async () => {
    const wrapper = renderBulkEditFlyout()

    await wrapper.findByLabelText('State')

    expect(wrapper.queryByLabelText('Text')).not.toBeInTheDocument()

    await wrapper.events.click(wrapper.getByLabelText('Note'))

    expect(await wrapper.findByLabelText('Text')).toBeInTheDocument()
  })

  it('validates required fields when adding a note', async () => {
    mockTicketUpdateBulkMutation({
      ticketUpdateBulk: {
        async: false,
        failedCount: 0,
        total: 2,
        invalidTicketIds: [],
      },
    })

    const wrapper = renderBulkEditFlyout()

    await wrapper.findByLabelText('State')

    await wrapper.events.click(wrapper.getByLabelText('Note'))

    await wrapper.events.click(wrapper.getByLabelText('Group'))

    await wrapper.events.click(wrapper.getByRole('option', { name: 'test group' }))

    await wrapper.events.click(wrapper.getByRole('button', { name: 'Apply' }))

    // Form validation should prevent submission with empty note body
    // Check that an error is displayed for the Text field
    expect(await wrapper.findByText('This field is required.')).toBeInTheDocument()
  })
})
