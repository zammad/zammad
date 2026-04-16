// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { computed } from 'vue'

import { renderComponent } from '#tests/support/components/index.ts'
import '#tests/graphql/builders/mocks.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import { mockFormUpdaterQuery } from '#shared/components/Form/graphql/queries/formUpdater.mocks.ts'
import { mockMacrosQuery, waitForMacrosQueryCalls } from '#shared/graphql/queries/macros.mocks.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import type { TicketBulkEditReturn } from '#desktop/components/Ticket/TicketBulkEditFlyout/types.ts'
import {
  TICKET_BULK_EDIT_SYMBOL,
  type TicketBulkSearchContext,
} from '#desktop/components/Ticket/TicketBulkEditFlyout/useTicketBulkEdit.ts'

import DragAndDropBulkWrapper, { type Props } from '../DragAndDropBulkWrapper.vue'

const defaultProps: Props = {
  cursorPosition: { x: 100, y: 100 },
}

describe('DragAndDropBulkWrapper', () => {
  // CommonOverlayContainer teleports its backdrop to #app when fullscreen=true.
  let appDiv: HTMLDivElement

  beforeAll(() => {
    appDiv = document.createElement('div')
    appDiv.id = 'app'
    document.body.appendChild(appDiv)
  })

  afterAll(() => {
    document.body.removeChild(appDiv)
  })

  beforeEach(() => {
    mockPermissions(['ticket.agent'])
    mockFormUpdaterQuery({
      formUpdater: {
        fields: {
          group_id: { options: [] },
          owner_id: { options: [] },
        },
      },
    })
  })

  const renderWrapper = (
    props: Partial<Props> = {},
    ticketBulkEditReturn?: Partial<TicketBulkEditReturn>,
  ) => {
    const defaultBulkContext = { overviewId: convertToGraphQLId('Overview', '1') }

    return renderComponent(DragAndDropBulkWrapper, {
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

  it('does not show the confirmation dialog', () => {
    const wrapper = renderWrapper()
    expect(wrapper.queryByRole('dialog')).not.toBeInTheDocument()
  })

  it('shows "No macros available" when macros are loaded but empty', async () => {
    mockMacrosQuery({ macros: [] })

    const wrapper = renderWrapper()

    await waitForMacrosQueryCalls()

    expect(await wrapper.findByText('No macros available for selected tickets')).toBeVisible()
  })

  describe('macros selector', () => {
    it('uses overview selector when bulk count is present', async () => {
      mockMacrosQuery({ macros: [] })

      renderWrapper()

      const calls = await waitForMacrosQueryCalls()

      expect(calls.at(-1)?.variables).toEqual({
        selector: { overviewId: convertToGraphQLId('Overview', '1') },
      })
    })

    it('uses search query selector when bulk context comes from search', async () => {
      mockMacrosQuery({ macros: [] })

      const searchContext: TicketBulkSearchContext = { searchQuery: 'priority:1 state:open' }

      renderWrapper(
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

      renderWrapper(
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
