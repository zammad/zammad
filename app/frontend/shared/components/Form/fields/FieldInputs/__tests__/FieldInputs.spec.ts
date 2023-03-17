// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { getNode } from '@formkit/core'
import { FormKit } from '@formkit/vue'
import { renderComponent } from '@tests/support/components'
import { waitForTimeout } from '@tests/support/utils'

const wrapperParameters = {
  form: true,
  formField: true,
  unmount: false,
}

describe('Form - Field - Inputs (Text) (Formkit-BuildIn)', () => {
  const wrapper = renderComponent(FormKit, {
    ...wrapperParameters,
    props: {
      name: 'text',
      type: 'text',
      id: 'text',
      label: 'Title',
    },
  })

  afterAll(() => {
    wrapper.unmount()
  })

  it('can render a input', () => {
    const input = wrapper.getByLabelText('Title')

    expect(input).toHaveAttribute('id', 'text')
    expect(input).toHaveAttribute('type', 'text')
    expect(input).not.toHaveAttribute('placeholder')

    const node = getNode('text')
    expect(node?.value).toBe(undefined)
  })

  it('set some props', async () => {
    await wrapper.rerender({
      label: 'Title',
      help: 'This is the help text',
      placeholder: 'Enter your title',
      maxlength: 100,
      minlength: 10,
    })

    expect(wrapper.getByText('This is the help text')).toBeInTheDocument()

    const input = wrapper.getByLabelText('Title')

    expect(input).toHaveAttribute('placeholder', 'Enter your title')
    expect(input).toHaveAttribute('maxlength', '100')
    expect(input).toHaveAttribute('minlength', '10')
  })

  it('check for the input event', async () => {
    const input = wrapper.getByLabelText('Title')

    await wrapper.events.clear(input)
    await wrapper.events.type(input, 'Example')

    await waitForTimeout()

    expect(wrapper.emitted().inputRaw).toBeTruthy()

    const emittedInput = wrapper.emitted().inputRaw as Array<Array<InputEvent>>

    expect(emittedInput[6][0]).toBe('Example')
  })

  it('can be disabled', async () => {
    const input = wrapper.getByLabelText('Title')

    expect(input).toBeEnabled()

    await wrapper.rerender({
      disabled: true,
    })

    expect(input).toBeDisabled()

    // Rest the disabled state again and check if it's enabled again.
    await wrapper.rerender({
      disabled: false,
    })

    expect(input).toBeEnabled()
  })
})

describe('Form - Field - Email (Formkit-BuildIn)', () => {
  const wrapper = renderComponent(FormKit, {
    ...wrapperParameters,
    props: {
      name: 'email',
      type: 'email',
      id: 'email',
      value: 'admin@example.com',
    },
  })

  afterAll(() => {
    wrapper.unmount()
  })

  it('can render a email input', () => {
    const input = wrapper.getByDisplayValue('admin@example.com')
    expect(input).toBeInTheDocument()
    expect(input).toHaveAttribute('type', 'email')

    const node = getNode('email')
    expect(node?.value).toBe('admin@example.com')
  })
})

describe('Form - Field - Color (Formkit-BuildIn)', () => {
  const wrapper = renderComponent(FormKit, {
    ...wrapperParameters,
    props: {
      name: 'color',
      type: 'color',
      id: 'color',
      label: 'Color',
    },
  })

  afterAll(() => {
    wrapper.unmount()
  })

  it('can render a color input', () => {
    expect(wrapper.getByLabelText('Color')).toHaveAttribute('type', 'color')
  })
})

describe('Form - Field - Tel (Formkit-BuildIn)', () => {
  const wrapper = renderComponent(FormKit, {
    ...wrapperParameters,
    props: {
      name: 'tel',
      type: 'tel',
      id: 'tel',
      label: 'Tel',
    },
  })

  afterAll(() => {
    wrapper.unmount()
  })

  it('can render a tel input', () => {
    expect(wrapper.getByLabelText('Tel')).toHaveAttribute('type', 'tel')
  })
})

describe('Form - Field - Number (Formkit-BuildIn)', () => {
  const wrapper = renderComponent(FormKit, {
    ...wrapperParameters,
    props: {
      name: 'number',
      type: 'number',
      id: 'number',
      min: 1,
      max: 10,
      step: 'auto',
      label: 'Number',
    },
  })

  afterAll(() => {
    wrapper.unmount()
  })

  it('can render a number input', () => {
    const input = wrapper.getByLabelText('Number')

    expect(input).toHaveAttribute('type', 'number')

    expect(input).toHaveAttribute('min', '1')
    expect(input).toHaveAttribute('max', '10')
    expect(input).toHaveAttribute('step', 'auto')
  })
})

describe('Form - Field - Time (Formkit-BuildIn)', () => {
  const wrapper = renderComponent(FormKit, {
    ...wrapperParameters,
    props: {
      name: 'time',
      type: 'time',
      id: 'time',
      label: 'Time',
    },
  })

  afterAll(() => {
    wrapper.unmount()
  })

  it('can render a time input', () => {
    const input = wrapper.getByLabelText('Time')
    expect(input).toHaveAttribute('type', 'time')
  })
})

describe('Form - Field - Url (Formkit-BuildIn)', () => {
  const wrapper = renderComponent(FormKit, {
    ...wrapperParameters,
    props: {
      name: 'url',
      type: 'url',
      id: 'url',
      label: 'url',
    },
  })

  afterAll(() => {
    wrapper.unmount()
  })

  it('can render a url input', () => {
    expect(wrapper.getByLabelText('url')).toHaveAttribute('type', 'url')
  })
})
