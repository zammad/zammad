// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { describe } from 'vitest'

import { renderComponent } from '#tests/support/components/index.ts'

import CommonTab from '#desktop/components/CommonTabGroup/CommonTab.vue'

describe('CommonTab', () => {
  it('renders passed label', () => {
    const wrapper = renderComponent(CommonTab, {
      props: {
        label: 'foo',
        size: 'medium',
      },
    })

    expect(wrapper.getByText('foo')).toBeInTheDocument()
  })

  it('renders passed count', () => {
    const wrapper = renderComponent(CommonTab, {
      props: {
        label: 'foo',
        size: 'medium',
        count: 99,
      },
    })

    expect(wrapper.getByText('99')).toBeInTheDocument()
  })
})
