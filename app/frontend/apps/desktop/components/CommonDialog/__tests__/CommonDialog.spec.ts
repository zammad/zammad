// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { flushPromises } from '@vue/test-utils'
import { afterAll, beforeAll } from 'vitest'

import { renderComponent } from '#tests/support/components/index.ts'

import CommonDialog from '../CommonDialog.vue'
import { getDialogMeta, openDialog } from '../useDialog.ts'

const html = String.raw

describe('visuals for common dialog', () => {
  beforeAll(() => {
    const main = document.createElement('main')
    main.id = 'page-main-content'
    document.body.appendChild(main)
  })

  beforeEach(() => {
    const { dialogsOptions } = getDialogMeta()
    dialogsOptions.set('dialog', {
      name: 'dialog',
      component: vi.fn().mockResolvedValue({}),
      refocus: true,
    })
  })
  afterAll(() => {
    document.body.innerHTML = ''
  })

  it('rendering with header title and content', () => {
    const view = renderComponent(CommonDialog, {
      props: {
        name: 'dialog',
        headerTitle: 'Some Title',
      },
      slots: {
        default: 'Content Slot',
      },
    })

    expect(view.getByText('Some Title')).toBeInTheDocument()
    expect(view.getByText('Content Slot')).toBeInTheDocument()
    expect(view.getByLabelText('Close dialog')).toBeInTheDocument()
  })

  it('can render header title as slot', () => {
    const view = renderComponent(CommonDialog, {
      props: {
        name: 'dialog',
      },
      slots: {
        header: 'Some Title',
      },
    })

    expect(view.getByText('Some Title')).toBeInTheDocument()
  })

  it('can close dialog with keyboard and clicks', async () => {
    const view = renderComponent(CommonDialog, {
      props: {
        name: 'dialog',
      },
      global: {
        stubs: {
          teleport: true,
        },
      },
    })

    await flushPromises()

    await view.events.keyboard('{Escape}')

    const emitted = view.emitted()

    expect(emitted.close).toHaveLength(1)
    expect(emitted.close[0]).toEqual([true])

    await view.events.click(view.getByLabelText('Close dialog'))
    expect(emitted.close).toHaveLength(2)

    await view.events.click(view.getByRole('button', { name: 'OK' }))
    expect(emitted.close).toHaveLength(3)
    expect(emitted.close[2]).toEqual([false])
  })

  it('rendering different footer button content', () => {
    const view = renderComponent(CommonDialog, {
      props: {
        name: 'dialog',
        headerTitle: 'Some Title',
        footerActionOptions: {
          actionLabel: 'Yes, continue',
        },
      },
      slots: {
        default: 'Content Slot',
      },
    })

    expect(
      view.getByRole('button', { name: 'Yes, continue' }),
    ).toBeInTheDocument()
  })

  it('has an accessible name', async () => {
    const view = renderComponent(CommonDialog, {
      props: {
        headerTitle: 'foobar',
        name: 'dialog',
      },
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
    expect(view.getByRole('button', { name: 'Cancel & Go Back' })).toHaveFocus()

    await view.events.keyboard('{Tab}')
    expect(view.getByRole('button', { name: 'OK' })).toHaveFocus()

    await view.events.keyboard('{Tab}')
    expect(view.getByLabelText('Close dialog')).toHaveFocus()

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

  it('focuses close, if there is nothing focusable in dialog', async () => {
    const view = renderComponent(CommonDialog, {
      props: {
        name: 'dialog',
        hideFooter: true,
      },
    })

    await flushPromises()

    expect(view.getByLabelText('Close dialog')).toHaveFocus()
  })

  it('refocuses element that opened dialog', async () => {
    const button = document.createElement('button')
    button.setAttribute('aria-haspopup', 'dialog')
    button.setAttribute('aria-controls', 'dialog-dialog')
    button.setAttribute('data-test-id', 'button')
    document.body.appendChild(button)

    button.focus()

    expect(button).toHaveFocus()

    await openDialog('dialog', {})

    const view = renderComponent(CommonDialog, {
      props: {
        name: 'dialog',
        hideFooter: true,
      },
    })

    await flushPromises()

    expect(view.getByLabelText('Close dialog')).toHaveFocus()

    await view.events.keyboard('{Escape}')

    expect(button).toHaveFocus()
  })
})
