// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { getNode } from '@formkit/core'
import { FormKit } from '@formkit/vue'
import { fireEvent } from '@testing-library/vue'

import { renderComponent } from '#tests/support/components/index.ts'
import { waitForNextTick, waitForTimeout } from '#tests/support/utils.ts'

const wrapperParameters = {
  form: true,
  formField: true,
}

const defaultProps: {
  name?: string
  type?: string
  id?: string
  label?: string
  placeholder?: string
  help?: string
  maxlength?: number
  minlength?: number
} = {
  name: 'password',
  type: 'password',
  id: 'password',
  label: 'Password',
}

const renderFieldPassword = (props = defaultProps) =>
  renderComponent(FormKit, {
    ...wrapperParameters,
    props,
  })

describe('Form - Field - Password (Formkit-BuildIn)', () => {
  it('can render an input', () => {
    const wrapper = renderFieldPassword()
    const input = wrapper.getByLabelText('Password')

    expect(input).toHaveAttribute('id', 'password')
    expect(input).toHaveAttribute('type', 'password')
    expect(input).not.toHaveAttribute('placeholder')

    const node = getNode('password')
    expect(node?.value).toBe('')
  })

  it('set some props', async () => {
    const wrapper = renderFieldPassword({
      label: 'Password',
      help: 'This is the help text',
      placeholder: 'Enter your password',
      maxlength: 32,
      minlength: 8,
    })

    expect(wrapper.getByText('This is the help text')).toBeInTheDocument()

    const input = wrapper.getByLabelText('Password')

    expect(input).toHaveAttribute('placeholder', 'Enter your password')
    expect(input).toHaveAttribute('maxlength', '32')
    expect(input).toHaveAttribute('minlength', '8')
  })

  it('check for the input event', async () => {
    const wrapper = renderFieldPassword()

    const input = wrapper.getByLabelText('Password')

    await wrapper.events.type(input, 'Test1234!')
    await waitForTimeout()

    const emittedInput = wrapper.emitted().inputRaw as Array<Array<InputEvent>>

    expect(emittedInput[8][0]).toBe('Test1234!')
  })

  it('can be disabled', async () => {
    const wrapper = renderFieldPassword()

    const input = wrapper.getByLabelText('Password')

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

describe('toggling visibility', () => {
  it('can show and hide password', async () => {
    const wrapper = renderFieldPassword()

    const input = wrapper.getByLabelText('Password')

    const toggleButton = wrapper.getByRole('button')

    // Mouse
    // Show
    await wrapper.events.click(toggleButton)
    await waitForNextTick(true)

    expect(input).toHaveAttribute('type', 'text')
    expect(wrapper.getByIconName('hide')).toBeInTheDocument()

    // Hide
    await wrapper.events.click(toggleButton)

    expect(wrapper.getByIconName('show')).toBeInTheDocument()
    expect(input).toHaveAttribute('type', 'password')

    // Keystroke
    // Show
    await fireEvent.keyDown(toggleButton, {
      key: 'Space',
      code: 'Space',
    })

    expect(wrapper.getByIconName('hide')).toBeInTheDocument()
    expect(input).toHaveAttribute('type', 'text')

    // Hide
    await fireEvent.keyDown(toggleButton, {
      key: 'Space',
      code: 'Space',
    })

    expect(wrapper.getByIconName('show')).toBeInTheDocument()
    expect(input).toHaveAttribute('type', 'password')
  })
})
