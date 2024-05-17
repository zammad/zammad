// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { getNode } from '@formkit/core'
import { FormKit } from '@formkit/vue'
import { getAllByRole } from '@testing-library/vue'

import { renderComponent } from '#tests/support/components/index.ts'
import type { ExtendedMountingOptions } from '#tests/support/components/index.ts'
import { waitForTimeout } from '#tests/support/utils.ts'

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

describe('Form - Field - Checkbox (FormKit built-in)', () => {
  it('can render a checkbox', () => {
    const view = renderCheckbox()

    const checkbox = view.getByLabelText('Checkbox')

    expect(checkbox).toHaveAttribute('id', 'checkbox')
    expect(checkbox).toHaveAttribute('type', 'checkbox')

    const node = getNode('checkbox')
    expect(node?.value).toBe(undefined)
  })

  it('renders a checkmark icon and `is-checked` data attribute', async () => {
    const view = renderCheckbox()

    const label = view.getByTestId('checkbox-label')

    expect(label.querySelector('svg')).toMatchInlineSnapshot(`
      <svg
        class="fill-current"
        height="16"
        viewBox="0 0 24 24"
        width="16"
        xmlns="http://www.w3.org/2000/svg"
      >
        <path
          d="M20.8087 5.58815L11.3542 18.5881C11.1771 18.8316 10.8998 18.9824 10.5992 18.9985C10.2986 19.0147 10.0067 18.8946 9.80449 18.6715L3.25903 11.4493L4.74097 10.1062L10.4603 16.4169L19.1913 4.4118L20.8087 5.58815Z"
        />
      </svg>
    `)

    expect(label).not.toHaveAttribute('data-is-checked')

    const checkbox = view.getByLabelText('Checkbox')

    await view.events.click(checkbox)

    expect(label).toHaveAttribute('data-is-checked', 'true')
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
