// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { getNode } from '@formkit/core'
import { FormKit } from '@formkit/vue'

import { renderComponent } from '#tests/support/components/index.ts'
import type { ExtendedRenderResult } from '#tests/support/components/index.ts'
import { waitForNextTick, waitForTimeout } from '#tests/support/utils.ts'

const wrapperParameters = {
  form: true,
  formField: true,
  unmount: false,
}

describe('Form - Field - Password (Formkit-BuildIn)', () => {
  let wrapper: ExtendedRenderResult

  beforeAll(() => {
    wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        name: 'password',
        type: 'password',
        id: 'password',
        label: 'Password',
      },
    })
  })

  afterAll(() => {
    wrapper.unmount()
  })

  it('can render an input', () => {
    const input = wrapper.getByLabelText('Password')

    expect(input).toHaveAttribute('id', 'password')
    expect(input).toHaveAttribute('type', 'password')
    expect(input).not.toHaveAttribute('placeholder')

    const node = getNode('password')
    expect(node?.value).toBe('')
  })

  it('set some props', async () => {
    await wrapper.rerender({
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
    const input = wrapper.getByLabelText('Password')

    await wrapper.events.type(input, 'Test1234!')
    await waitForTimeout()

    const emittedInput = wrapper.emitted().inputRaw as Array<Array<InputEvent>>

    expect(emittedInput[8][0]).toBe('Test1234!')
  })

  it('can be disabled', async () => {
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
  let wrapper: ExtendedRenderResult

  beforeAll(() => {
    wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        type: 'password',
        label: 'Password',
      },
    })
  })

  afterAll(() => {
    wrapper.unmount()
  })

  it('can show password', async () => {
    const input = wrapper.getByLabelText('Password')

    const iconToggle = wrapper.getByIconName('show')

    await wrapper.events.click(iconToggle)
    await waitForNextTick(true)

    expect(input).toHaveAttribute('type', 'text')
    expect(wrapper.getByIconName('hide')).toBeInTheDocument()
  })

  it('can hide password', async () => {
    const input = wrapper.getByLabelText('Password')

    const iconToggle = wrapper.getByIconName('hide')

    await wrapper.events.click(iconToggle)
    await waitForNextTick(true)

    await waitForNextTick(true)

    expect(input).toHaveAttribute('type', 'password')
    expect(wrapper.getByIconName('show')).toBeInTheDocument()
  })
})
