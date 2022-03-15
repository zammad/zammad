// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { getNode } from '@formkit/core'
import { FormKit } from '@formkit/vue'
import { getWrapper } from '@tests/support/components'

const wrapperParameters = {
  form: true,
  formField: true,
}

const wrapper = getWrapper(FormKit, {
  ...wrapperParameters,
  props: {
    name: 'hidden',
    type: 'hidden',
    id: 'hidden',
    value: 'example-value',
  },
})

describe('Form - Field - Hidden (Formkit-BuildIn)', () => {
  it('mounts successfully', () => {
    expect(wrapper.exists()).toBe(true)
  })

  it('can render a input', () => {
    expect(wrapper.html()).toContain('<input')
    expect(wrapper.find('input').attributes().id).toBe('hidden')
    expect(wrapper.find('input').attributes().type).toBe('hidden')

    const node = getNode('hidden')
    expect(node?.value).toBe('example-value')
  })
})
