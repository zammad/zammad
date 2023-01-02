// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { getNode } from '@formkit/core'
import { FormKit } from '@formkit/vue'
import { getAllByRole } from '@testing-library/vue'
import type { ExtendedMountingOptions } from '@tests/support/components'
import { renderComponent } from '@tests/support/components'
import { waitForTimeout } from '@tests/support/utils'

const wrapperParameters = {
  form: true,
  formField: true,
}

const renderCheckbox = (options: ExtendedMountingOptions<unknown> = {}) =>
  renderComponent(FormKit, {
    ...wrapperParameters,
    props: {
      name: 'checkbox',
      type: 'checkbox',
      id: 'checkbox',
      label: 'Checkbox',
    },
    ...options,
  })

describe('Form - Field - Checkbox (Formkit-BuildIn)', () => {
  it('can render a checkbox', () => {
    const view = renderCheckbox()

    const checkbox = view.getByLabelText('Checkbox')

    expect(checkbox).toHaveAttribute('id', 'checkbox')
    expect(checkbox).toHaveAttribute('type', 'checkbox')

    const node = getNode('checkbox')
    expect(node?.value).toBe(undefined)
  })

  it('set some props', async () => {
    const view = renderCheckbox({
      props: {
        label: 'Checkbox',
        type: 'checkbox',
        help: 'This is the help text',
      },
    })

    expect(view.getByLabelText('Checkbox')).toBeInTheDocument()
    expect(view.getByText(/This is the help text/)).toBeInTheDocument()
  })

  it('check for the input event', async () => {
    const view = renderCheckbox({
      props: {
        label: 'Checkbox',
        type: 'checkbox',
        help: 'This is the help text',
      },
    })

    const checkbox = view.getByLabelText('Checkbox')
    await view.events.click(checkbox)

    await waitForTimeout()

    expect(view.emitted().inputRaw).toBeTruthy()

    const emittedInput = view.emitted().inputRaw as Array<Array<InputEvent>>

    expect(emittedInput[0][0]).toBe(true)
  })

  it('check for the input value when on-value and off-value is used', async () => {
    const view = renderCheckbox({
      props: {
        label: 'Checkbox',
        name: 'checkbox',
        type: 'checkbox',
        id: 'checkbox',
        onValue: 'yes',
        offValue: 'no',
      },
    })

    const checkbox = view.getByLabelText('Checkbox')
    await view.events.click(checkbox)

    await waitForTimeout()

    expect(view.emitted().inputRaw).toBeTruthy()

    let emittedInput = view.emitted().inputRaw as Array<Array<InputEvent>>

    expect(emittedInput[0][0]).toBe('yes')

    await view.events.click(checkbox)

    await waitForTimeout()

    emittedInput = view.emitted().inputRaw as Array<Array<InputEvent>>
    expect(emittedInput[1][0]).toBe('no')
  })

  it('can be disabled', async () => {
    const view = renderCheckbox({
      props: {
        label: 'Checkbox',
        name: 'checkbox',
        type: 'checkbox',
        id: 'checkbox',
      },
    })

    const checklist = view.getByLabelText('Checkbox')

    expect(checklist).not.toHaveAttribute('disabled')

    await view.rerender({
      disabled: true,
    })

    expect(checklist).toHaveAttribute('disabled')

    // Rest the disabled state again and check if it's enabled again.
    await view.rerender({
      disabled: false,
    })

    expect(checklist).not.toHaveAttribute('disabled')
  })

  it('options for multiple checkboxes can be used', () => {
    const view = renderCheckbox({
      props: {
        label: 'Multiple Checkbox',
        name: 'checkbox-multiple',
        type: 'checkbox',
        id: 'checkbox-multiple',
        options: ['one', 'two', 'three'],
      },
    })

    const fieldset = view.getByRole('group', { name: /Multiple Checkbox/ })

    expect(fieldset).toBeInTheDocument()

    const inputs = getAllByRole(fieldset, 'checkbox')

    expect(inputs).toHaveLength(3)

    const node = getNode('checkbox-multiple')
    expect(node?.value).toStrictEqual([])
  })

  it('check for the multiple checkbox input event', async () => {
    const view = renderCheckbox({
      props: {
        label: 'Multiple Checkbox',
        name: 'checkbox-multiple',
        type: 'checkbox',
        id: 'checkbox-multiple',
        options: ['one', 'two', 'three'],
      },
    })

    await view.events.click(view.getByLabelText(/one/))
    await waitForTimeout()

    expect(view.emitted().inputRaw).toBeTruthy()

    const emittedInput = view.emitted().inputRaw as Array<Array<InputEvent>>

    expect(emittedInput[0][0]).toStrictEqual(['one'])

    await view.events.click(view.getByLabelText(/three/))
    await waitForTimeout()

    expect(emittedInput[1][0]).toStrictEqual(['one', 'three'])
  })
})
