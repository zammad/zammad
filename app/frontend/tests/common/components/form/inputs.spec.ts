// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

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
    name: 'text',
    type: 'text',
    id: 'text',
  },
})

describe('FormField - Inputs (Text) (Formkit-BuildIn)', () => {
  it('mounts successfully', () => {
    expect(wrapper.exists()).toBe(true)
  })

  it('can render a input', () => {
    expect(wrapper.html()).toContain('formkit-outer')
    expect(wrapper.html()).toContain('formkit-wrapper')
    expect(wrapper.html()).toContain('formkit-inner')
    expect(wrapper.html()).toContain('<input')
    expect(wrapper.find('input').attributes().id).toBe('text')
    expect(wrapper.find('input').attributes().type).toBe('text')
    expect(wrapper.find('input').attributes().placeholder).toBeUndefined()
    expect(wrapper.find('label').exists()).toBe(false)

    const node = getNode('text')
    expect(node?.value).toBe(undefined)
  })

  it('set some props', async () => {
    expect.assertions(5)

    wrapper.setProps({
      label: 'Title',
      help: 'This is the help text',
      placeholder: 'Enter your title',
      maxlength: 100,
      minlength: 10,
    })

    await nextTick()

    expect(wrapper.find('label').text()).toBe('Title')
    expect(wrapper.find('.formkit-help').text()).toBe('This is the help text')

    const attributes = wrapper.find('input').attributes()
    expect(attributes.placeholder).toBe('Enter your title')
    expect(attributes.maxlength).toBe('100')
    expect(attributes.minlength).toBe('10')
  })

  it('check for the input event', async () => {
    expect.assertions(2)
    const input = wrapper.find('input')
    input.setValue('example title')
    input.trigger('input')

    await new Promise((resolve) => {
      setTimeout(resolve, 0)
    })

    expect(wrapper.emitted('input')).toBeTruthy()

    const emittedInput = wrapper.emitted().input as Array<Array<InputEvent>>

    expect(emittedInput[0][0]).toBe('example title')
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
})

describe('FormField - Email (Formkit-BuildIn)', () => {
  it('mounts successfully', () => {
    wrapper = getWrapper(FormKit, {
      ...wrapperParameters,
      props: {
        name: 'email',
        type: 'email',
        id: 'email',
        value: 'admin@example.com',
      },
    })
    expect(wrapper.exists()).toBe(true)
  })

  it('can render a email input', () => {
    expect(wrapper.html()).toContain('<input')
    expect(wrapper.find('input').attributes().type).toBe('email')
  })

  it('has default value', () => {
    expect(wrapper.find('input').element.value).toBe('admin@example.com')

    const node = getNode('email')
    expect(node?.value).toBe('admin@example.com')
  })
})

describe('FormField - Color (Formkit-BuildIn)', () => {
  it('mounts successfully', () => {
    wrapper = getWrapper(FormKit, {
      ...wrapperParameters,
      props: {
        name: 'color',
        type: 'color',
        id: 'color',
      },
    })
    expect(wrapper.exists()).toBe(true)
  })

  it('can render a color input', () => {
    expect(wrapper.html()).toContain('<input')
    expect(wrapper.find('input').attributes().type).toBe('color')
  })
})

describe('FormField - Tel (Formkit-BuildIn)', () => {
  it('mounts successfully', () => {
    wrapper = getWrapper(FormKit, {
      ...wrapperParameters,
      props: {
        name: 'tel',
        type: 'tel',
        id: 'tel',
      },
    })
    expect(wrapper.exists()).toBe(true)
  })

  it('can render a tel input', () => {
    expect(wrapper.html()).toContain('<input')
    expect(wrapper.find('input').attributes().type).toBe('tel')
  })
})

describe('FormField - Search (Formkit-BuildIn)', () => {
  it('mounts successfully', () => {
    wrapper = getWrapper(FormKit, {
      ...wrapperParameters,
      props: {
        name: 'search',
        type: 'search',
        id: 'search',
      },
    })
    expect(wrapper.exists()).toBe(true)
  })

  it('can render a search input', () => {
    expect(wrapper.html()).toContain('<input')
    expect(wrapper.find('input').attributes().type).toBe('search')
  })
})

describe('FormField - Number (Formkit-BuildIn)', () => {
  it('mounts successfully', () => {
    wrapper = getWrapper(FormKit, {
      ...wrapperParameters,
      props: {
        name: 'number',
        type: 'number',
        id: 'number',
        min: 1,
        max: 10,
        step: 'auto',
      },
    })
    expect(wrapper.exists()).toBe(true)
  })

  it('can render a number input', () => {
    expect(wrapper.html()).toContain('<input')
    expect(wrapper.find('input').attributes().type).toBe('number')

    const attributes = wrapper.find('input').attributes()
    expect(attributes.min).toBe('1')
    expect(attributes.max).toBe('10')
    expect(attributes.step).toBe('auto')
  })
})

describe('FormField - Time (Formkit-BuildIn)', () => {
  it('mounts successfully', () => {
    wrapper = getWrapper(FormKit, {
      ...wrapperParameters,
      props: {
        name: 'time',
        type: 'time',
        id: 'time',
      },
    })
    expect(wrapper.exists()).toBe(true)
  })

  it('can render a time input', () => {
    expect(wrapper.html()).toContain('<input')
    expect(wrapper.find('input').attributes().type).toBe('time')
  })
})

describe('FormField - Date (Formkit-BuildIn)', () => {
  it('mounts successfully', () => {
    wrapper = getWrapper(FormKit, {
      ...wrapperParameters,
      props: {
        name: 'date',
        type: 'date',
        id: 'date',
      },
    })
    expect(wrapper.exists()).toBe(true)
  })

  it('can render a date input', () => {
    expect(wrapper.html()).toContain('<input')
    expect(wrapper.find('input').attributes().type).toBe('date')
  })
})

describe('FormField - Datetime (Formkit-BuildIn)', () => {
  it('mounts successfully', () => {
    wrapper = getWrapper(FormKit, {
      ...wrapperParameters,
      props: {
        name: 'datetimeLocal',
        type: 'datetimeLocal',
        id: 'datetimeLocal',
      },
    })
    expect(wrapper.exists()).toBe(true)
  })

  it('can render a datetimeLocal input', () => {
    expect(wrapper.html()).toContain('<input')
    expect(wrapper.find('input').attributes().type).toBe('datetimeLocal')
  })
})
