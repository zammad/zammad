// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'

import TicketListPopoverSkeleton from '../TicketListPopoverSkeleton.vue'

describe('TicketListPopoverSkeleton', () => {
  it('renders the skeleton correctly', () => {
    const wrapper = renderComponent(TicketListPopoverSkeleton, {
      props: { loading: true },
    })

    expect(wrapper.getAllByRole('progressbar').length).toBe(6)
  })
})
