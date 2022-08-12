// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '@tests/support/components'
import { flushPromises } from '@vue/test-utils'
import { ref } from 'vue'
import CommonSectionPopup from '../CommonSectionPopup.vue'
import type { PopupItem } from '../types'

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
})
