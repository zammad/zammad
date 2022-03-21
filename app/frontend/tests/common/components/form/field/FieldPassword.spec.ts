// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { getNode } from '@formkit/core'
import { FormKit } from '@formkit/vue'
import { getWrapper } from '@tests/support/components'
import { waitForNextTick, waitForTimeout } from '@tests/support/utils'
import { nextTick } from 'vue'

const wrapperParameters = {
  form: true,
  formField: true,
}

let wrapper = getWrapper(FormKit, {
  ...wrapperParameters,
  props: {
    name: 'password',
    type: 'password',
    id: 'password',
  },
})

describe('Form - Field - Password (Formkit-BuildIn)', () => {
  it('mounts successfully', () => {
    expect(wrapper.exists()).toBe(true)
  })

  it('can render a input', () => {
    expect(wrapper.html()).toContain('formkit-outer')
    expect(wrapper.html()).toContain('formkit-wrapper')
    expect(wrapper.html()).toContain('formkit-inner')
    expect(wrapper.html()).toContain('<input')
    expect(wrapper.find('input').attributes().id).toBe('password')
    expect(wrapper.find('input').attributes().type).toBe('password')
    expect(wrapper.find('input').attributes().placeholder).toBeUndefined()
    expect(wrapper.find('label').exists()).toBe(false)

    const node = getNode('password')
    expect(node?.value).toBe(undefined)
  })

  it('set some props', async () => {
    expect.assertions(5)

    wrapper.setProps({
      label: 'Password',
      help: 'This is the help text',
      placeholder: 'Enter your password',
      maxlength: 32,
      minlength: 8,
    })

    await nextTick()

    expect(wrapper.find('label').text()).toBe('Password')
    expect(wrapper.find('.formkit-help').text()).toBe('This is the help text')

    const attributes = wrapper.find('input').attributes()
    expect(attributes.placeholder).toBe('Enter your password')
    expect(attributes.maxlength).toBe('32')
    expect(attributes.minlength).toBe('8')
  })

  it('check for the input event', async () => {
    expect.assertions(2)
    const input = wrapper.find('input')
    input.setValue('Test1234!')
    input.trigger('input')

    await waitForTimeout()

    expect(wrapper.emitted('input')).toBeTruthy()

    const emittedInput = wrapper.emitted().input as Array<Array<InputEvent>>

    expect(emittedInput[0][0]).toBe('Test1234!')
  })

  it('can be disabled', async () => {
    expect.assertions(3)
    expect(wrapper.find('input').attributes().disabled).toBe(undefined)

    wrapper.setProps({
      disabled: true,
    })
    await nextTick()

    expect(wrapper.find('input').attributes().disabled).toBeDefined()

    // Rest the disabled state again and check if it's enabled again.
    wrapper.setProps({
      disabled: false,
    })
    await nextTick()

    expect(wrapper.find('input').attributes().disabled).toBe(undefined)
  })

  it('can show password', async () => {
    expect.assertions(2)

    wrapper = getWrapper(FormKit, {
      ...wrapperParameters,
      props: {
        type: 'password',
      },
    })

    wrapper.find('svg').trigger('click')

    await waitForNextTick(true)

    expect(wrapper.find('input').attributes().type).toBe('text')
    expect(wrapper.find('svg').classes()).contains('icon-eye-off')
  })

  it('can hide password', async () => {
    expect.assertions(2)

    wrapper.find('svg').trigger('click')

    await waitForNextTick(true)

    expect(wrapper.find('input').attributes().type).toBe('password')
    expect(wrapper.find('svg').classes()).contains('icon-eye')
  })
})
