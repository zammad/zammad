// Copyright (C) 2012-2021 Zammad Foundation, https://zammad-foundation.org/

import TransitionViewNavigation from '@mobile/components/transition/TransitionViewNavigation.vue'
import { shallowMount } from '@vue/test-utils'

describe('TransitionViewNavigation.vue', () => {
  it('renders the component', () => {
    const wrapper = shallowMount(TransitionViewNavigation)

    expect(wrapper.exists()).toBe(true)
  })
})
