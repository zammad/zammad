// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { flushPromises } from '@vue/test-utils'
import { computed } from 'vue'

import renderComponent from '#tests/support/components/renderComponent.ts'

import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'
import QueryHandler from '#shared/server/apollo/handler/QueryHandler.ts'

import TicketPopover from '../TicketPopoverWithTrigger/TicketPopover.vue'

import '#tests/graphql/builders/mocks.ts'

describe('OrganizationPopover', () => {
  it('shows a skeleton when ticket is loading', async (context) => {
    context.skipConsole = true

    vi.useFakeTimers()
    vi.spyOn(QueryHandler.prototype, 'loadingWithoutCachedResult').mockReturnValue(
      computed(() => true),
    )

    const wrapper = renderComponent(TicketPopover, {
      props: {
        ticket: createDummyTicket(),
      },
      router: true,
    })

    await flushPromises()
    await vi.advanceTimersByTimeAsync(0)

    const skeletons = await wrapper.findAllByLabelText('Content loader')

    expect(skeletons.length).toBeGreaterThan(0)

    vi.useRealTimers()
    vi.restoreAllMocks()
  })
})
