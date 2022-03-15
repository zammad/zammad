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
    name: 'group',
    type: 'group',
    id: 'group',
  },
})

describe('Form - Field - Group (Formkit-BuildIn)', () => {
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
        name: 'group',
        type: 'group',
        id: 'group',
      },
      slots: {
        default: `<fieldset><FormKit type="text" name="text" id="text" value="example-value" />
          <FormKit type="checkbox" name="checkbox" id="checkbox" v-bind:value="true" /></fieldset>`,
      },
    })

    // TODO - Remove the .get() here when @vue/test-utils > rc.19
    const inputs = wrapper.get('fieldset').findAll('input')
    expect(inputs.length).toBe(2)

    const node = getNode('group')
    expect(node?.value).toStrictEqual({
      text: 'example-value',
      checkbox: true,
    })
  })
})
