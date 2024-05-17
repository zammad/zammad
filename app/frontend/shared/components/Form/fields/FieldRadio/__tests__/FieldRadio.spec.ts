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

const renderRadio = (options: ExtendedMountingOptions<unknown> = {}) =>
  renderComponent(FormKit, {
    ...wrapperParameters,
    props: {
      name: 'radio',
      type: 'radio',
      id: 'radio',
      label: 'Radio',
      help: 'This is the help text',
      options: ['Option 1', 'Option 2', 'Option 3'],
    },
    ...options,
  })

describe('Form - Field - Radio (FormKit built-in)', () => {
  it('can render a radio', () => {
    const view = renderRadio()

    const fieldset = view.getByRole('group', { name: /Radio/ })

    expect(fieldset).toBeInTheDocument()

    expect(view.getByText(/This is the help text/)).toBeInTheDocument()

    const node = getNode('radio')
    expect(node?.value).toBe(undefined)
  })

  it('renders a checkmark icon and `is-checked` data attribute', async () => {
    const view = renderRadio()

    const [label] = view.getAllByTestId('radio-label')

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

    const radio = view.getByLabelText('Option 1')

    await view.events.click(radio)

    expect(label).toHaveAttribute('data-is-checked', 'true')
  })

  it('options are visible', () => {
    const view = renderRadio()

    const fieldset = view.getByRole('group', { name: /Radio/ })

    expect(fieldset).toBeInTheDocument()

    const inputs = getAllByRole(fieldset, 'radio')

    expect(inputs).toHaveLength(3)
  })

  it('check for the input event', async () => {
    const view = renderRadio()

    const radio = view.getByLabelText('Option 2')
    await view.events.click(radio)

    await waitForTimeout()

    expect(view.emitted().inputRaw).toBeTruthy()

    const emittedInput = view.emitted().inputRaw as Array<Array<InputEvent>>

    expect(emittedInput[0][0]).toBe('Option 2')

    const node = getNode('radio')
    expect(node?.value).toBe('Option 2')
  })

  it('can use button mode', async () => {
    const view = renderRadio({
      props: {
        name: 'radio',
        type: 'radio',
        id: 'radio',
        label: 'Radio',
        options: ['Option 1', 'Option 2'],
        buttons: true,
      },
    })

    expect(view.getByLabelText('Option 1')).toHaveClass('sr-only')
    expect(view.getByLabelText('Option 2')).toHaveClass('sr-only')
  })

  it('can show option icon', async () => {
    const view = renderRadio({
      props: {
        name: 'radio',
        type: 'radio',
        id: 'radio',
        label: 'Radio',
        options: [
          {
            label: 'Option 1',
            value: 1,
            icon: 'mail-out',
          },
          {
            label: 'Option 2',
            value: 2,
            icon: 'clock',
          },
        ],
        buttons: true,
      },
    })

    expect(view.getByIconName('clock')).toBeInTheDocument()
    expect(view.getByIconName('mail-out')).toBeInTheDocument()
  })

  it('can be disabled', async () => {
    const view = renderRadio({
      props: {
        name: 'radio',
        type: 'radio',
        id: 'radio',
        label: 'Radio',
        options: ['Option 1', 'Option 2'],
        buttons: true,
      },
    })

    const radio = view.getByLabelText('Option 1')

    expect(radio).not.toHaveAttribute('disabled')

    await view.rerender({
      disabled: true,
    })

    expect(radio).toHaveAttribute('disabled')

    // Rest the disabled state again and check if it's enabled again.
    await view.rerender({
      disabled: false,
    })

    expect(radio).not.toHaveAttribute('disabled')
  })
})
