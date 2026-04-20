// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { computed } from 'vue'

import { renderComponent } from '#tests/support/components/index.ts'

import { mockMacrosQuery, waitForMacrosQueryCalls } from '#shared/graphql/queries/macros.mocks.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import type { TicketBulkEditReturn } from '#desktop/components/Ticket/TicketBulkEditFlyout/types.ts'
import {
  TICKET_BULK_EDIT_SYMBOL,
  type TicketBulkSearchContext,
} from '#desktop/components/Ticket/TicketBulkEditFlyout/useTicketBulkEdit.ts'

import DragAndDropBulkTopDrawer from '../DragAndDropBulkTopDrawer.vue'

const macros = [
  { internalId: 1, name: 'Close ticket' },
  { internalId: 2, name: 'Assign to support' },
]

const defaultProps = {
  isActive: false,
  dropSuccessTargetEntity: null,
}

const renderTopDrawer = (
  props: Partial<typeof defaultProps> = {},
  ticketBulkEditReturn?: Partial<TicketBulkEditReturn>,
) => {
  const defaultBulkContext = { overviewId: convertToGraphQLId('Overview', '1') }

  return renderComponent(DragAndDropBulkTopDrawer, {
    props: { ...defaultProps, ...props },
    router: true,
    store: true,
    provide: [
      [
        TICKET_BULK_EDIT_SYMBOL,
        {
          bulkSelector: computed(() => defaultBulkContext),
          macrosSelector: computed(() => defaultBulkContext),
          ...ticketBulkEditReturn,
        },
      ],
    ],
  })
}

describe('DragAndDropBulkTopDrawer', () => {
  describe('loading state', () => {
    it('shows skeleton while macros are loading', () => {
      mockMacrosQuery({ macros })
      const wrapper = renderTopDrawer()

      expect(wrapper.getByRole('progressbar', { name: 'Content loader' })).toBeInTheDocument()
    })
  })

  describe('inactive state', () => {
    it('shows the circle "Run macro" placeholder when macros are available', async () => {
      mockMacrosQuery({ macros })
      const wrapper = renderTopDrawer()

      await waitForMacrosQueryCalls()

      expect(await wrapper.findByText('Run macro')).toBeInTheDocument()
    })

    it('does not show individual macro names in circle mode', async () => {
      mockMacrosQuery({ macros })
      const wrapper = renderTopDrawer()

      await waitForMacrosQueryCalls()

      expect(wrapper.queryByText('Close ticket')).not.toBeInTheDocument()
      expect(wrapper.queryByText('Assign to support')).not.toBeInTheDocument()
    })
  })

  describe('active state', () => {
    it('shows individual macro names in the list', async () => {
      mockMacrosQuery({ macros })
      const wrapper = renderTopDrawer({ isActive: true })

      await waitForMacrosQueryCalls()

      expect(await wrapper.findByText('Close ticket')).toBeInTheDocument()
      expect(await wrapper.findByText('Assign to support')).toBeInTheDocument()
    })

    it('shows the "Run macro" heading rendered as h3', async () => {
      mockMacrosQuery({ macros })
      const wrapper = renderTopDrawer({ isActive: true })

      await waitForMacrosQueryCalls()

      expect(
        await wrapper.findByRole('heading', { level: 3, name: 'Run macro' }),
      ).toBeInTheDocument()
    })
  })

  describe('empty state', () => {
    it('shows "No macros available" when macros array is empty', async () => {
      mockMacrosQuery({ macros: [] })

      const wrapper = renderTopDrawer()

      await waitForMacrosQueryCalls()

      expect(
        await wrapper.findByText('No macros available for selected tickets'),
      ).toBeInTheDocument()
    })

    describe('macros selector', () => {
      it('uses overview selector when bulk count is present', async () => {
        mockMacrosQuery({ macros: [] })

        renderTopDrawer()

        const calls = await waitForMacrosQueryCalls()

        expect(calls.at(-1)?.variables).toEqual({
          selector: { overviewId: convertToGraphQLId('Overview', '1') },
        })
      })

      it('uses search query selector when bulk context comes from search', async () => {
        mockMacrosQuery({ macros: [] })

        const searchContext: TicketBulkSearchContext = { searchQuery: 'priority:1 state:open' }

        renderTopDrawer(
          {},
          {
            bulkSelector: computed(() => searchContext),
            macrosSelector: computed(() => searchContext),
          },
        )

        const calls = await waitForMacrosQueryCalls()

        expect(calls.at(-1)?.variables).toEqual({
          selector: searchContext,
        })
      })

      it('uses entity ids selector when bulk count is zero', async () => {
        mockMacrosQuery({ macros: [] })

        const groupIds = [convertToGraphQLId('Group', 1), convertToGraphQLId('Group', 2)]

        const entityContext = {
          entityIds: [convertToGraphQLId('Ticket', 1)],
        }

        renderTopDrawer(
          {},
          {
            bulkCount: computed(() => 0),
            groupIds: computed(() => groupIds),
            bulkSelector: computed(() => entityContext),
            macrosSelector: computed(() => entityContext),
          },
        )

        const calls = await waitForMacrosQueryCalls()

        expect(calls.at(-1)?.variables).toEqual({
          selector: entityContext,
        })
      })
    })
  })
})
