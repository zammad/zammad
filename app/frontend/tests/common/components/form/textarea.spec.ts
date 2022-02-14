// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { i18n } from '@common/utils/i18n'
import { getNode } from '@formkit/core'
import { FormKit } from '@formkit/vue'
import { getWrapper } from '@tests/support/components'
import { nextTick } from 'vue'

const wrapperParameters = {
  form: true,
}

let wrapper = getWrapper(FormKit, {
  ...wrapperParameters,
  props: {
    name: 'textarea',
    type: 'textarea',
    id: 'textarea',
  },
})

describe('FormField - Textarea (Formkit-BuildIn)', () => {
  it('mounts successfully', () => {
    expect(wrapper.exists()).toBe(true)
  })

  it('can render a textarea', () => {
    expect(wrapper.html()).toContain('formkit-outer')
    expect(wrapper.html()).toContain('formkit-wrapper')
    expect(wrapper.html()).toContain('formkit-inner')
    expect(wrapper.html()).toContain('<textarea')
    expect(wrapper.find('textarea').attributes().id).toBe('textarea')
    expect(wrapper.find('textarea').attributes().placeholder).toBeUndefined()
    expect(wrapper.find('label').exists()).toBe(false)

    const node = getNode('textarea')
    expect(node?.value).toBe(undefined)
  })

  it('set some props', async () => {
    expect.assertions(7)

    wrapper.setProps({
      label: 'Body',
      help: 'This is the help text',
      placeholder: 'Enter your body',
      cols: 10,
      maxlength: 100,
      minlength: 10,
      rows: 5,
    })

    await nextTick()

    expect(wrapper.find('label').text()).toBe('Body')
    expect(wrapper.find('.formkit-help').text()).toBe('This is the help text')

    const attributes = wrapper.find('textarea').attributes()
    expect(attributes.placeholder).toBe('Enter your body')
    expect(attributes.cols).toBe('10')
    expect(attributes.rows).toBe('5')
    expect(attributes.maxlength).toBe('100')
    expect(attributes.minlength).toBe('10')
  })

  it('check for the input event', async () => {
    expect.assertions(2)
    const textarea = wrapper.find('textarea')
    textarea.setValue('example body')
    textarea.trigger('input')

    await new Promise((resolve) => {
      setTimeout(resolve, 0)
    })

    expect(wrapper.emitted('input')).toBeTruthy()

    const emittedInput = wrapper.emitted().input as Array<Array<InputEvent>>

    expect(emittedInput[0][0]).toBe('example body')
  })

  it('can be disabled', async () => {
    expect.assertions(3)
    expect(wrapper.find('textarea').attributes().disabled).toBe(undefined)

    wrapper.setProps({
      disabled: true,
    })
    await nextTick()

    expect(wrapper.find('textarea').attributes().disabled).toBeDefined()

    // Rest the disabled state again and check if it's enabled again.
    wrapper.setProps({
      disabled: false,
    })
    await nextTick()

    expect(wrapper.find('textarea').attributes().disabled).toBe(undefined)
  })

  it('can translate placeholder attribute', async () => {
    expect.assertions(2)

    wrapper = getWrapper(FormKit, {
      ...wrapperParameters,
      props: {
        label: 'Body',
        help: 'This is the help text',
        placeholder: 'Enter your body',
        name: 'textarea',
        type: 'textarea',
        id: 'textarea',
      },
    })

    expect(wrapper.find('textarea').attributes().placeholder).toBe(
      'Enter your body',
    )

    const map = new Map([['Enter your body', 'Gib deinen Text ein']])

    i18n.setTranslationMap(map)

    await nextTick()

    expect(wrapper.find('textarea').attributes().placeholder).toBe(
      'Gib deinen Text ein',
    )
  })

  it('can translate label with label placeholder', () => {
    wrapper = getWrapper(FormKit, {
      ...wrapperParameters,
      props: {
        label: 'Body %s %s',
        labelPlaceholder: ['Example', 'Placeholder'],
        name: 'textarea',
        type: 'textarea',
        id: 'textarea',
      },
    })

    expect(wrapper.find('label').exists()).toBe(true)
    expect(wrapper.find('label').element.textContent).toBe(
      'Body Example Placeholder',
    )
  })
})
