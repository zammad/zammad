// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'

import TransitionViewNavigation from '../TransitionViewNavigation.vue'

describe('TransitionViewNavigation.vue', () => {
  it('renders the component', () => {
    const wrapper = renderComponent(TransitionViewNavigation)

    expect(wrapper.container).toBeInTheDocument()
  })
})
