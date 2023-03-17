// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '@tests/support/components'
import CommonSelectPill from '../CommonSelectPill.vue'

const options = [
  { value: '1', label: 'Option 1' },
  { value: '2', label: 'Option 2' },
]

describe('testing small button to trigger select', () => {
  // most of the select functionality is tested inside CommonSelect, this is just a wrapper

  it('should open select dialog', async () => {
    const view = renderComponent(CommonSelectPill, {
      props: {
        placeholder: 'Label',
        options,
      },
      vModel: {
        modelValue: null,
      },
      dialog: true,
    })

    const button = view.getByRole('button', { name: 'Label' })
    expect(button).toBeInTheDocument()

    await view.events.click(button)

    expect(view.getByRole('dialog')).toBeInTheDocument()

    await view.events.click(view.getByRole('option', { name: 'Option 1' }))

    expect(view.getByRole('button', { name: 'Option 1' })).toBeInTheDocument()
  })

  it('should render slot', () => {
    const view = renderComponent(CommonSelectPill, {
      props: {
        options,
      },
      slots: {
        default: '<div data-test-id="slot">Slot</div>',
      },
    })

    expect(view.getByTestId('slot')).toBeInTheDocument()
  })

  it('returns focus when closing dialog', async () => {
    const view = renderComponent(CommonSelectPill, {
      props: {
        placeholder: 'Label',
        options,
      },
      vModel: {
        modelValue: null,
      },
      dialog: true,
    })

    const openButton = view.getByRole('button', { name: 'Label' })
    expect(openButton).toBeInTheDocument()

    await view.events.click(openButton)

    expect(view.getByRole('option', { name: 'Option 1' })).toBeInTheDocument()

    await view.events.keyboard('{Escape}')

    expect(openButton).toHaveFocus()
  })
})
