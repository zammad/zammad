// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import FormLayout from '@common/components/form/FormLayout.vue'
import { getWrapper } from '@tests/support/components'

const wrapper = getWrapper(FormLayout, {
  props: {},
  slots: {
    default: 'Should be a field',
  },
})

describe('FormLayout.vue', () => {
  it('mounts successfully', () => {
    expect(wrapper.exists()).toBe(true)
  })

  it('check the output', () => {
    expect(wrapper.html()).toContain('fieldset')
    expect(wrapper.html()).toContain('Should be a field')
    expect(wrapper.find('fieldset').classes()).toContain('column-1')
  })

  // TODO: more real live test cases with fields, when the component usage is more clear.
})
