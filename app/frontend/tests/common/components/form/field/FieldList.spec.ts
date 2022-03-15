// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { getNode } from '@formkit/core'
import { FormKit } from '@formkit/vue'
import { getWrapper } from '@tests/support/components'

const wrapperParameters = {
  form: true,
  formField: true,
}

let wrapper = getWrapper(FormKit, {
  ...wrapperParameters,
  props: {
    name: 'list',
    type: 'list',
    id: 'list',
  },
})

describe('Form - Field - List (Formkit-BuildIn)', () => {
  it('mounts successfully', () => {
    expect(wrapper.exists()).toBe(true)
  })

  it('empty content without childrens', () => {
    expect(wrapper.html()).toContain('')
  })

  it('render some fields and check values', () => {
    wrapper = getWrapper(FormKit, {
      ...wrapperParameters,
      props: {
        name: 'list',
        type: 'list',
        id: 'list',
      },
      slots: {
        default: `<fieldset><FormKit type="text" name="email-adress" id="text" value="admin@example.com" />
          <FormKit type="text" name="email-adress" id="text" value="admin2@example.com" /></fieldset>`,
      },
    })

    // TODO - Remove the .get() here when @vue/test-utils > rc.19
    const inputs = wrapper.get('fieldset').findAll('input')
    expect(inputs.length).toBe(2)

    const node = getNode('list')
    expect(node?.value).toStrictEqual([
      'admin@example.com',
      'admin2@example.com',
    ])
  })
})
