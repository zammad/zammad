// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { flushPromises } from '@vue/test-utils'
import { ref } from 'vue'

import { renderComponent } from '#tests/support/components/index.ts'

import CommonSectionPopup from '../CommonSectionPopup.vue'

import type { PopupItemDescriptor } from '../types.ts'

const html = String.raw

describe('popup behaviour', () => {
  it('renders list', async () => {
    const onAction = vi.fn()
    const messages: PopupItemDescriptor[] = [
      {
        type: 'link',
        label: 'Link',
        link: '/',
      },
      {
        type: 'button',
        label: 'Action',
        onAction,
      },
    ]

    const view = renderComponent(CommonSectionPopup, {
      props: {
        messages,
      },
      router: true,
      vModel: {
        state: true,
      },
    })

    const [linkItem, actionItem] = messages

    const link = view.getByText(linkItem.label)
    const action = view.getByText(actionItem.label)

    expect(link).toBeInTheDocument()
    expect(action).toBeInTheDocument()

    expect(view.getLinkFromElement(link)).toHaveAttribute('href', '/mobile/')

    await view.events.click(action)

    expect(onAction).toHaveBeenCalledOnce()
  })

  it('can close list', async () => {
    const state = ref(true)

    const view = renderComponent(CommonSectionPopup, {
      props: {
        messages: [],
      },
      vModel: {
        state,
      },
    })

    await view.events.click(view.getByText('Cancel'))

    expect(view.queryByTestId('popupWindow')).not.toBeInTheDocument()

    state.value = true
    await flushPromises()

    expect(view.queryByTestId('popupWindow')).toBeInTheDocument()

    await view.events.click(document.body)

    expect(view.queryByTestId('popupWindow')).not.toBeInTheDocument()
  })

  it('autofocuses fist element and traps focus inside', async () => {
    const externalForm = document.createElement('form')
    externalForm.innerHTML = html`
      <input data-test-id="form_input" type="text" />
      <select data-test-id="form_select" type="text" />
    `

    document.body.appendChild(externalForm)

    const messages: PopupItemDescriptor[] = [
      {
        type: 'link',
        label: 'Link',
        link: '/',
      },
      {
        type: 'button',
        label: 'Action',
        onAction: vi.fn(),
      },
    ]

    const view = renderComponent(CommonSectionPopup, {
      props: {
        messages,
      },
      router: true,
      vModel: {
        state: true,
      },
    })

    await flushPromises()

    // auto focused on first item
    expect(view.getByText('Link')).toHaveFocus()

    await view.events.keyboard('{Tab}')

    expect(view.getByRole('button', { name: 'Action' })).toHaveFocus()

    await view.events.keyboard('{Tab}')

    expect(view.getByRole('button', { name: 'Cancel' })).toHaveFocus()

    await view.events.keyboard('{Tab}')

    expect(view.getByText('Link')).toHaveFocus()
  })

  it('refocuses on the last element that opened popup', async () => {
    const button = document.createElement('button')
    button.setAttribute('data-test-id', 'button')
    document.body.appendChild(button)

    button.focus()

    expect(button).toHaveFocus()

    const view = renderComponent(CommonSectionPopup, {
      props: {
        messages: [],
      },
      router: true,
      vModel: {
        state: true,
      },
    })

    await flushPromises()

    expect(button).not.toHaveFocus()

    await view.events.keyboard('{Escape}')

    expect(button).toHaveFocus()
  })

  it("doesn't refocuses on the last element that opened popup, when specified", async () => {
    const button = document.createElement('button')
    button.setAttribute('data-test-id', 'button')
    document.body.appendChild(button)

    button.focus()

    expect(button).toHaveFocus()

    const view = renderComponent(CommonSectionPopup, {
      props: {
        messages: [],
        noRefocus: true,
      },
      router: true,
      vModel: {
        state: true,
      },
    })

    await flushPromises()

    expect(button).not.toHaveFocus()

    await view.events.keyboard('{Escape}')

    expect(button).not.toHaveFocus()
  })

  it('closes list after clicking', async () => {
    const messages: PopupItemDescriptor[] = [
      {
        type: 'button',
        label: 'Hide Popup',
      },
      {
        type: 'button',
        label: 'Keep Popup',
        noHideOnSelect: true,
      },
    ]

    const view = renderComponent(CommonSectionPopup, {
      props: {
        messages,
      },
      router: true,
      vModel: {
        state: true,
      },
    })

    const [hideItem, keepItem] = messages

    await view.events.click(view.getByText(keepItem.label))

    expect(view.queryByTestId('popupWindow')).toBeInTheDocument()

    await view.events.click(view.getByText(hideItem.label))

    expect(view.queryByTestId('popupWindow')).not.toBeInTheDocument()
  })

  it('renders text message', async () => {
    const messages: PopupItemDescriptor[] = [
      {
        type: 'text',
        label: 'Some kind of text',
      },
    ]

    const view = renderComponent(CommonSectionPopup, {
      props: {
        messages,
      },
      router: true,
      vModel: {
        state: true,
      },
    })

    expect(view.getByText('Some kind of text')).toBeInTheDocument()

    await view.events.click(view.getByText('Some kind of text'))

    expect(view.queryByTestId('popupWindow')).toBeInTheDocument()
  })
})
