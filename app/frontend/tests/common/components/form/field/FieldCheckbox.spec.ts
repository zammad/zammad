// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import CheckboxVariant from '@common/types/form/fields'
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
    name: 'checkbox',
    type: 'checkbox',
    id: 'checkbox',
    variant: CheckboxVariant.default,
  },
})

describe('Form - Field - Checkbox (Formkit-BuildIn)', () => {
  it('mounts successfully', () => {
    expect(wrapper.exists()).toBe(true)
  })

  it('can render a checkbox', () => {
    expect(wrapper.html()).toContain('formkit-outer')
    expect(wrapper.html()).toContain('formkit-wrapper')
    expect(wrapper.html()).toContain('formkit-inner')
    expect(wrapper.html()).toContain('<input')
    expect(wrapper.find('input').attributes().id).toBe('checkbox')
    expect(wrapper.find('input').attributes().type).toBe('checkbox')
    expect(wrapper.find('span.formkit-label').exists()).toBe(false)

    const node = getNode('checkbox')
    expect(node?.value).toBe(undefined)
  })

  it('set some props', async () => {
    expect.assertions(2)

    wrapper.setProps({
      label: 'Checkbox',
      help: 'This is the help text',
    })

    await nextTick()

    expect(wrapper.find('span.formkit-label').text()).toBe('Checkbox')
    expect(wrapper.find('.formkit-help').text()).toBe('This is the help text')
  })

  it('check for the input event', async () => {
    expect.assertions(2)
    const checkbox = wrapper.find('input')
    checkbox.element.checked = true
    checkbox.trigger('input')

    await waitForTimeout()

    expect(wrapper.emitted('input')).toBeTruthy()

    const emittedInput = wrapper.emitted().input as Array<Array<InputEvent>>

    expect(emittedInput[0][0]).toBe(true)
  })

  it('check for the input value when on-value and off-value is used', async () => {
    expect.assertions(4)

    wrapper = getWrapper(FormKit, {
      ...wrapperParameters,
      props: {
        label: 'Checkbox',
        name: 'checkbox',
        type: 'checkbox',
        id: 'checkbox',
        onValue: 'yes',
        offValue: 'no',
      },
    })

    const checkbox = wrapper.find('input')
    checkbox.element.checked = true
    checkbox.trigger('input')

    await waitForTimeout()

    expect(wrapper.emitted('input')).toBeTruthy()

    let emittedInput = wrapper.emitted().input as Array<Array<InputEvent>>

    expect(emittedInput[0][0]).toBe('yes')

    // Reset the first input event.
    delete wrapper.emitted().input

    checkbox.element.checked = false
    checkbox.trigger('input')

    await waitForTimeout()

    expect(wrapper.emitted('input')).toBeTruthy()
    emittedInput = wrapper.emitted().input as Array<Array<InputEvent>>
    expect(emittedInput[0][0]).toBe('no')
  })

  it('can use variant', async () => {
    expect.assertions(1)

    wrapper.setProps({
      variant: CheckboxVariant.switch,
    })
    await waitForNextTick(true)

    // Normal checkbox should not be visible.
    expect(wrapper.find('input').classes()).contains('sr-only')
  })

  it('can be disabled', async () => {
    expect.assertions(4)
    expect(wrapper.find('input').attributes().disabled).toBe(undefined)

    wrapper.setProps({
      disabled: true,
    })
    await nextTick()

    expect(wrapper.find('input').attributes().disabled).toBeDefined()
    expect(wrapper.find('.formkit-wrapper[data-disabled]').exists()).toBe(true)

    // Rest the disabled state again and check if it's enabled again.
    wrapper.setProps({
      disabled: false,
    })
    await nextTick()

    expect(wrapper.find('input').attributes().disabled).toBe(undefined)
  })

  it('options for multiple checkboxes can be used', () => {
    wrapper = getWrapper(FormKit, {
      ...wrapperParameters,
      props: {
        label: 'Multiple Checkbox',
        name: 'checkbox-multiple',
        type: 'checkbox',
        id: 'checkbox-multiple',
        options: ['one', 'two', 'three'],
      },
    })

    // TODO - Remove the .get() here when @vue/test-utils > rc.19
    const inputs = wrapper.get('fieldset').findAll('input')
    expect(inputs.length).toBe(3)
    expect(wrapper.find('legend').text()).toBe('Multiple Checkbox')

    const node = getNode('checkbox-multiple')
    expect(node?.value).toStrictEqual([])
  })

  it('check for the multiple checkbox input event', async () => {
    expect.assertions(3)
    const checkboxes = wrapper.get('fieldset').findAll('input')
    checkboxes[0].element.checked = true
    checkboxes[0].trigger('input')

    await waitForTimeout()

    expect(wrapper.emitted('input')).toBeTruthy()

    const emittedInput = wrapper.emitted().input as Array<Array<InputEvent>>

    expect(emittedInput[0][0]).toStrictEqual(['one'])

    checkboxes[2].element.checked = true
    checkboxes[2].trigger('input')

    await waitForTimeout()

    expect(emittedInput[1][0]).toStrictEqual(['one', 'three'])
  })
})
