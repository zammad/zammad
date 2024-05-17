// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { getByIconName } from '#tests/support/components/iconQueries.ts'
import { renderComponent } from '#tests/support/components/index.ts'
import { getTestRouter } from '#tests/support/components/renderComponent.ts'

import CommonButtonGroup from '../CommonButtonGroup.vue'

import type { CommonButtonOption } from '../types.ts'

describe('buttons group', () => {
  it('renders a list of buttons', async () => {
    const onAction = vi.fn()

    const options: CommonButtonOption[] = [
      {
        label: 'link %s',
        labelPlaceholder: ['text'],
        link: '/example',
        value: 'link',
      },
      { label: 'button', onAction, value: 'button' },
      {
        label: 'with-icon',
        onAction,
        icon: 'home',
        disabled: true,
        value: 'icon',
      },
    ]

    const view = renderComponent(CommonButtonGroup, {
      props: { options, modelValue: 'button' },
      router: true,
      store: true,
    })

    expect(view.getByRole('link', { name: 'link text' })).toHaveAttribute(
      'href',
      '/mobile/example',
    )

    const button = view.getByRole('button', { name: 'button' })

    expect(button).toBeEnabled()
    expect(button, 'selected button has a class').toHaveClass('!bg-gray-200')

    await view.events.click(button)

    expect(onAction).toHaveBeenCalled()

    const iconButton = view.getByRole('button', { name: 'with-icon' })

    expect(iconButton).toBeDisabled()
    expect(getByIconName(iconButton, 'home')).toBeInTheDocument()
  })

  it("doesn't call action, if disabled", async () => {
    const onAction = vi.fn()

    const options: CommonButtonOption[] = [
      { label: 'link', link: '/example', disabled: true },
      { label: 'button', onAction, disabled: true },
    ]

    const view = renderComponent(CommonButtonGroup, {
      props: { options },
    })

    const button = view.getByRole('button', { name: 'button' })
    const link = view.getByRole('link', { name: 'link' })

    expect(button).toBeDisabled()

    const router = getTestRouter()
    const currentUrl = router.currentRoute.value.fullPath

    await view.events.click(button)
    await view.events.click(link)

    expect(onAction).not.toHaveBeenCalled()
    expect(router.currentRoute.value.fullPath).toBe(currentUrl)
  })
})
