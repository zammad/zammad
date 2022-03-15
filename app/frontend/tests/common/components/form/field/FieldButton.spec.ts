// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { FormKit } from '@formkit/vue'
import { getWrapper } from '@tests/support/components'
import { nextTick } from 'vue'

const wrapperParameters = {
  form: true,
  formField: true,
}

let wrapper = getWrapper(FormKit, {
  ...wrapperParameters,
  props: {
    name: 'button',
    type: 'button',
    id: 'button',
  },
  slots: {
    default: 'Sign In',
  },
})

describe('Form - Field - Button (Formkit-BuildIn)', () => {
  it('mounts successfully', () => {
    expect(wrapper.exists()).toBe(true)
  })

  it('can render a button', () => {
    expect(wrapper.html()).toContain('formkit-outer')
    expect(wrapper.html()).toContain('formkit-wrapper')
    expect(wrapper.html()).toContain('<button')

    const button = wrapper.find('button')
    expect(button.attributes().id).toBe('button')
    expect(button.text()).toBe('Sign In')
  })

  it('can render a button with a label instead of slot', () => {
    wrapper = getWrapper(FormKit, {
      ...wrapperParameters,
      props: {
        name: 'button',
        type: 'button',
        id: 'button',
        label: 'Sign In',
      },
    })

    expect(wrapper.find('button').text()).toBe('Sign In')
  })

  it('can be disabled', async () => {
    expect.assertions(3)
    expect(wrapper.find('button').attributes().disabled).toBe(undefined)

    wrapper.setProps({
      disabled: true,
    })
    await nextTick()

    expect(wrapper.find('button').attributes().disabled).toBeDefined()

    // Rest the disabled state again and check if it's enabled again.
    wrapper.setProps({
      disabled: false,
    })
    await nextTick()

    expect(wrapper.find('button').attributes().disabled).toBe(undefined)
  })
})

describe('Form - Field - Submit-Button (Formkit-BuildIn)', () => {
  it('mounts successfully', () => {
    wrapper = getWrapper(FormKit, {
      ...wrapperParameters,
      props: {
        name: 'submit',
        type: 'submit',
        id: 'submit',
      },
      slots: {
        default: 'Sign In',
      },
    })
    expect(wrapper.exists()).toBe(true)
  })

  it('can render a button', () => {
    expect(wrapper.html()).toContain('formkit-outer')
    expect(wrapper.html()).toContain('formkit-wrapper')
    expect(wrapper.html()).toContain('<button')

    const button = wrapper.find('button')
    expect(button.attributes().id).toBe('submit')
    expect(button.attributes().type).toBe('submit')
    expect(button.text()).toBe('Sign In')
  })
})

// TODO: Add test cases for new functionality, e.g. some loading state.
