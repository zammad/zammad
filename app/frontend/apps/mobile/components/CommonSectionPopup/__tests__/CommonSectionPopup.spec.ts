// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '@tests/support/components'
import { flushPromises } from '@vue/test-utils'
import { ref } from 'vue'
import CommonSectionPopup from '../CommonSectionPopup.vue'
import type { PopupItem } from '../types'

const html = String.raw

describe('popup behaviour', () => {
  it('renders list', async () => {
    const onAction = vi.fn()
    const items: PopupItem[] = [
      {
        label: 'Link',
        link: '/',
      },
      {
        label: 'Action',
        onAction,
      },
    ]

    const view = renderComponent(CommonSectionPopup, {
      props: {
        items,
      },
      router: true,
      vModel: {
        state: true,
      },
    })

    const [linkItem, actionItem] = items

    const link = view.getByText(linkItem.label)
    const action = view.getByText(actionItem.label)

    expect(link).toBeInTheDocument()
    expect(action).toBeInTheDocument()

    expect(view.getLinkFromElement(link)).toHaveAttribute('href', '/')

    await view.events.click(action)

    expect(onAction).toHaveBeenCalledOnce()
  })

  it('can close list', async () => {
    const state = ref(true)

    const view = renderComponent(CommonSectionPopup, {
      props: {
        items: [],
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

    const items: PopupItem[] = [
      {
        label: 'Link',
        link: '/',
      },
      {
        label: 'Action',
        onAction: vi.fn(),
      },
    ]

    const view = renderComponent(CommonSectionPopup, {
      props: {
        items,
      },
      router: true,
      vModel: {
        state: true,
      },
    })

    await flushPromises()

    // auto focused on first item
    expect(view.getByRole('link', { name: 'Link' })).toHaveFocus()

    await view.events.keyboard('{Tab}')

    expect(view.getByRole('button', { name: 'Action' })).toHaveFocus()

    await view.events.keyboard('{Tab}')

    expect(view.getByRole('button', { name: 'Cancel' })).toHaveFocus()

    await view.events.keyboard('{Tab}')

    expect(view.getByRole('link', { name: 'Link' })).toHaveFocus()
  })

  it('refocuses on the last element that opened popup', async () => {
    const button = document.createElement('button')
    button.setAttribute('data-test-id', 'button')
    document.body.appendChild(button)

    button.focus()

    expect(button).toHaveFocus()

    const view = renderComponent(CommonSectionPopup, {
      props: {
        items: [],
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
        items: [],
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
    const items: PopupItem[] = [
      {
        label: 'Hide Popup',
      },
      {
        label: 'Keep Popup',
        noHideOnSelect: true,
      },
    ]

    const view = renderComponent(CommonSectionPopup, {
      props: {
        items,
      },
      router: true,
      vModel: {
        state: true,
      },
    })

    const [hideItem, keepItem] = items

    await view.events.click(view.getByText(keepItem.label))

    expect(view.queryByTestId('popupWindow')).toBeInTheDocument()

    await view.events.click(view.getByText(hideItem.label))

    expect(view.queryByTestId('popupWindow')).not.toBeInTheDocument()
  })
})
