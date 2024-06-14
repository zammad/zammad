// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { describe } from 'vitest'

import { renderComponent } from '#tests/support/components/index.ts'

import CommonTab from '#desktop/components/CommonTabManager/CommonTab.vue'

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

  // :TODO visual regression test?
})
