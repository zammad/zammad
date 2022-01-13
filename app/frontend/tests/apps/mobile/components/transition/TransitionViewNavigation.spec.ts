// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import TransitionViewNavigation from '@mobile/components/transition/TransitionViewNavigation.vue'
import { getWrapper } from '@tests/support/components'

describe('TransitionViewNavigation.vue', () => {
  it('renders the component', () => {
    const wrapper = getWrapper(TransitionViewNavigation)

    expect(wrapper.exists()).toBe(true)
  })
})
