// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { flushPromises } from '@vue/test-utils'
import { computed } from 'vue'

import renderComponent from '#tests/support/components/renderComponent.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import QueryHandler from '#shared/server/apollo/handler/QueryHandler.ts'

import OrganizationPopover from '../OrganizationPopoverWithTrigger/OrganizationPopover.vue'

import '#tests/graphql/builders/mocks.ts'

describe('OrganizationPopover', () => {
  it('shows a skeleton when user info is not available', async () => {
    vi.useFakeTimers()

    vi.spyOn(QueryHandler.prototype, 'loadingWithoutCachedResult').mockReturnValue(
      computed(() => true),
    )
    const wrapper = renderComponent(OrganizationPopover, {
      props: {
        organizationAvatar: {
          id: '2',
          name: 'Dummy Organization',
          active: true,
          vip: false,
        },
      },
      router: true,
      form: true,
    })

    await flushPromises()
    await vi.advanceTimersByTimeAsync(0)
    await waitForNextTick()

    expect(wrapper.getAllByRole('progressbar').length).toBeGreaterThan(0)

    vi.useRealTimers()
    vi.resetAllMocks()
    await vi.dynamicImportSettled()
  })
})
