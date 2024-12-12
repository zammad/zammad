// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { flushPromises } from '@vue/test-utils'
import { afterAll, beforeAll, expect } from 'vitest'

import { renderComponent } from '#tests/support/components/index.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import CommonDialog from '../CommonDialog.vue'
import { getDialogMeta, useDialog } from '../useDialog.ts'

const html = String.raw

describe('visuals for common dialog', () => {
  let mainElement: HTMLElement
  let app: HTMLDivElement

  beforeAll(() => {
    app = document.createElement('div')
    app.id = 'app'
    document.body.appendChild(app)

    mainElement = document.createElement('main')
    mainElement.id = 'main-content'

    app.insertAdjacentElement('beforeend', mainElement)
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
    const wrapper = renderComponent(CommonDialog, {
      props: {
        name: 'dialog',
        headerTitle: 'Some Title',
      },
      slots: {
        default: 'Content Slot',
      },
      router: true,
    })

    expect(wrapper.getByText('Some Title')).toBeInTheDocument()
    expect(wrapper.getByText('Content Slot')).toBeInTheDocument()
    expect(wrapper.getByLabelText('Close dialog')).toBeInTheDocument()
  })

  it('can render header title as slot', () => {
    const wrapper = renderComponent(CommonDialog, {
      props: {
        name: 'dialog',
      },
      slots: {
        header: 'Some Title',
      },
      router: true,
    })

    expect(wrapper.getByText('Some Title')).toBeInTheDocument()
  })

  it('can close dialog with keyboard and clicks', async () => {
    const wrapper = renderComponent(CommonDialog, {
      props: {
        name: 'dialog',
      },
      global: {
        stubs: {
          teleport: true,
        },
      },
      router: true,
    })

    await flushPromises()

    await wrapper.events.keyboard('{Escape}')

    const emitted = wrapper.emitted()

    expect(emitted.close).toHaveLength(1)
    expect(emitted.close[0]).toEqual([undefined])

    await wrapper.events.click(wrapper.getByLabelText('Close dialog'))
    expect(emitted.close).toHaveLength(2)

    await wrapper.events.click(wrapper.getByRole('button', { name: 'OK' }))
    expect(emitted.close).toHaveLength(3)
    expect(emitted.close[2]).toEqual([false])
  })

  it('rendering different footer button content', () => {
    const wrapper = renderComponent(CommonDialog, {
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
      router: true,
    })

    expect(
      wrapper.getByRole('button', { name: 'Yes, continue' }),
    ).toBeInTheDocument()
  })

  it('has an accessible name', async () => {
    const wrapper = renderComponent(CommonDialog, {
      props: {
        headerTitle: 'foobar',
        name: 'dialog',
      },
      router: true,
    })

    expect(wrapper.getByRole('dialog')).toHaveAccessibleName('foobar')
  })

  it('traps focus inside the dialog', async () => {
    const externalForm = document.createElement('form')
    externalForm.innerHTML = html`
      <input data-test-id="form_input" type="text" />
      <select data-test-id="form_select" type="text" />
    `
    document.body.appendChild(externalForm)

    const wrapper = renderComponent(CommonDialog, {
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
      router: true,
    })

    wrapper.getByTestId('input').focus()
    expect(wrapper.getByTestId('input')).toHaveFocus()

    await wrapper.events.keyboard('{Tab}')
    expect(wrapper.getByTestId('div')).toHaveFocus()

    await wrapper.events.keyboard('{Tab}')
    expect(wrapper.getByTestId('select')).toHaveFocus()

    await wrapper.events.keyboard('{Tab}')
    expect(
      wrapper.getByRole('button', { name: 'Cancel & Go Back' }),
    ).toHaveFocus()

    await wrapper.events.keyboard('{Tab}')
    expect(wrapper.getByRole('button', { name: 'OK' })).toHaveFocus()

    await wrapper.events.keyboard('{Tab}')
    expect(wrapper.getByLabelText('Close dialog')).toHaveFocus()

    await wrapper.events.keyboard('{Tab}')
    expect(wrapper.getByTestId('input')).toHaveFocus()
  })

  it('autofocuses the first focusable element', async () => {
    const wrapper = renderComponent(CommonDialog, {
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
      router: true,
    })

    await flushPromises()

    expect(wrapper.getByTestId('div')).toHaveFocus()
  })

  it('focuses close, if there is nothing focusable in dialog', async () => {
    const wrapper = renderComponent(CommonDialog, {
      props: {
        name: 'dialog',
        hideFooter: true,
      },
    })

    await flushPromises()

    expect(wrapper.getByLabelText('Close dialog')).toHaveFocus()
  })

  it('refocuses element that opened dialog', async () => {
    const wrapper = renderComponent(
      {
        template: `
          <button aria-haspopup="dialog" aria-controls="dialog" data-test-id="button"/>`,
        setup() {
          const dialog = useDialog({
            name: 'dialog',
            component: () =>
              import('#desktop/components/CommonDialog/CommonDialog.vue'),
          })
          dialog.open({ name: 'dialog', hideFooter: true })
        },
      },
      {
        dialog: true,
        router: true,
      },
    )

    await wrapper.events.click(wrapper.getByTestId('button'))

    expect(wrapper.getByTestId('button')).toHaveFocus()

    await wrapper.events.keyboard('{Escape}')

    await waitForNextTick()

    expect(wrapper.getByTestId('button')).toHaveFocus()
  })

  it('displays by default over the main content', () => {
    const wrapper = renderComponent(CommonDialog, {
      props: {
        name: 'dialog',
        fullscreen: false,
      },
    })

    expect(mainElement.children).not.include(wrapper.baseElement)
    expect(app.children).include(wrapper.baseElement)
  })

  it('supports displaying over entire viewport', () => {
    const wrapper = renderComponent(CommonDialog, {
      props: {
        name: 'dialog',
        fullscreen: true,
      },
    })

    expect(mainElement.children).include(wrapper.baseElement)
  })
})
