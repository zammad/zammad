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

describe('Form - Field - Radio (Formkit-BuildIn)', () => {
  it('can render a radio', () => {
    const view = renderRadio()

    const fieldset = view.getByRole('group', { name: /Radio/ })

    expect(fieldset).toBeInTheDocument()

    expect(view.getByText(/This is the help text/)).toBeInTheDocument()

    const node = getNode('radio')
    expect(node?.value).toBe(undefined)
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
            icon: 'mobile-mail-out',
          },
          {
            label: 'Option 2',
            value: 2,
            icon: 'mobile-clock',
          },
        ],
        buttons: true,
      },
    })

    expect(view.getByIconName('mobile-clock')).toBeInTheDocument()
    expect(view.getByIconName('mobile-mail-out')).toBeInTheDocument()
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
