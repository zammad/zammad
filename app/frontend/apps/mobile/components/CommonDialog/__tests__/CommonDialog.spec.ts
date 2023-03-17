// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { getDialogMeta, openDialog } from '@shared/composables/useDialog'
import { renderComponent } from '@tests/support/components'
import { flushPromises } from '@vue/test-utils'
import CommonDialog from '../CommonDialog.vue'

const html = String.raw

describe('visuals for common dialog', () => {
  beforeEach(() => {
    const { dialogsOptions } = getDialogMeta()
    dialogsOptions.set('dialog', {
      name: 'dialog',
      component: vi.fn().mockResolvedValue({}),
      refocus: true,
    })
  })

  it('rendering with label and content', () => {
    const view = renderComponent(CommonDialog, {
      props: {
        name: 'dialog',
        label: 'Some Label',
      },
      slots: {
        default: 'Content Slot',
      },
    })

    expect(view.getByText('Some Label')).toBeInTheDocument()
    expect(view.getByText('Content Slot')).toBeInTheDocument()
    expect(view.getByText('Done')).toBeInTheDocument()
  })

  it('can render label as slot', () => {
    const view = renderComponent(CommonDialog, {
      props: {
        name: 'dialog',
      },
      slots: {
        label: 'Some Label',
      },
    })

    expect(view.getByText('Some Label')).toBeInTheDocument()
  })

  it('can close dialog with keyboard and clicks', async () => {
    const view = renderComponent(CommonDialog, {
      props: {
        name: 'dialog',
      },
    })

    await flushPromises()

    await view.events.keyboard('{Escape}')

    const emitted = view.emitted()

    expect(emitted.close).toHaveLength(1)

    await view.events.click(view.getByRole('button', { name: /Done/ }))

    expect(emitted.close).toHaveLength(2)
  })

  it('has an accessible name', async () => {
    const view = renderComponent(CommonDialog, {
      props: {
        name: 'dialog',
      },
    })

    expect(view.getByRole('dialog')).toHaveAccessibleName('dialog')

    await view.rerender({
      label: 'foobar',
    })

    expect(view.getByRole('dialog')).toHaveAccessibleName('foobar')
  })

  it('traps focus inside the dialog', async () => {
    const externalForm = document.createElement('form')
    externalForm.innerHTML = html`
      <input data-test-id="form_input" type="text" />
      <select data-test-id="form_select" type="text" />
    `

    document.body.appendChild(externalForm)

    const view = renderComponent(CommonDialog, {
      props: {
        name: 'dialog',
      },
      slots: {
        default: html`
          <input data-test-id="input" type="text" />
          <div data-test-id="div" tabindex="0" />
          <select data-test-id="select">
            <option value="1">1</option>
          </select>
        `,
      },
    })

    view.getByTestId('input').focus()

    expect(view.getByTestId('input')).toHaveFocus()

    await view.events.keyboard('{Tab}')

    expect(view.getByTestId('div')).toHaveFocus()

    await view.events.keyboard('{Tab}')

    expect(view.getByTestId('select')).toHaveFocus()

    await view.events.keyboard('{Tab}')

    expect(view.getByRole('button', { name: 'Done' })).toHaveFocus()

    await view.events.keyboard('{Tab}')

    expect(view.getByTestId('input')).toHaveFocus()
  })

  it('autofocuses the first focusable element', async () => {
    const view = renderComponent(CommonDialog, {
      props: {
        name: 'dialog',
      },
      slots: {
        default: html`
          <div data-test-id="div" tabindex="0" />
          <select data-test-id="select">
            <option value="1">1</option>
          </select>
        `,
      },
    })

    await flushPromises()

    expect(view.getByTestId('div')).toHaveFocus()
  })

  it('focuses "Done", if there is nothing focusable in dialog', async () => {
    const view = renderComponent(CommonDialog, {
      props: {
        name: 'dialog',
      },
    })

    await flushPromises()

    expect(view.getByRole('button', { name: 'Done' })).toHaveFocus()
  })

  it('refocuses element that opened dialog', async () => {
    const button = document.createElement('button')
    button.setAttribute('data-test-id', 'button')
    document.body.appendChild(button)

    button.focus()

    expect(button).toHaveFocus()

    await openDialog('dialog', {})

    const view = renderComponent(CommonDialog, {
      props: {
        name: 'dialog',
      },
    })

    await flushPromises()

    expect(view.getByRole('button', { name: 'Done' })).toHaveFocus()

    await view.events.keyboard('{Escape}')

    expect(button).toHaveFocus()
  })

  // closing with pulling down is tested inside e2e
})
