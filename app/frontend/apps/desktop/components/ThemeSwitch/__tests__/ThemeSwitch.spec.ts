// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { ref, type Ref } from 'vue'

import { renderComponent } from '#tests/support/components/index.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import ThemeSwitch, { type Props } from '../ThemeSwitch.vue'

export const renderThemeSwitch = (props?: Props, modelValue?: Ref) => {
  return renderComponent(ThemeSwitch, {
    props,
    vModel: {
      modelValue,
    },
  })
}

describe('ThemeSwitch', () => {
  it('cycles between checkbox states', async () => {
    const view = renderThemeSwitch()
    const button = view.getByLabelText('Dark Mode')

    expect(button).toBePartiallyChecked()

    await view.events.click(button)

    expect(button).toBeChecked()

    await view.events.click(button)

    expect(button).not.toBeChecked()

    await view.events.click(button)

    expect(button).toBePartiallyChecked()
  })

  it('supports model-value', async () => {
    const appearance = ref('dark')
    const view = renderThemeSwitch({}, appearance)
    const button = view.getByLabelText('Dark Mode')

    expect(button).toBeChecked()

    appearance.value = 'light'

    await waitForNextTick()

    expect(button).not.toBeChecked()

    appearance.value = 'auto'

    await waitForNextTick()

    expect(button).toBePartiallyChecked()
  })

  it('supports size prop', async () => {
    const view = renderThemeSwitch({
      size: 'small',
    })

    const button = view.getByLabelText('Dark Mode')

    expect(button).toHaveClasses(['w-11', 'h-[19px]'])

    await view.rerender({
      size: 'medium',
    })

    expect(button).toHaveClasses(['w-14', 'h-6'])
  })

  it('renders appropriate icons', async () => {
    const appearance = ref('') // checks fallback handling
    const view = renderThemeSwitch({}, appearance)

    expect(view.getByIconName('magic')).toBeInTheDocument()

    appearance.value = 'dark'

    await waitForNextTick()

    expect(view.getByIconName('moon-stars')).toBeInTheDocument()

    appearance.value = 'light'

    await waitForNextTick()

    expect(view.getByIconName('sun')).toBeInTheDocument()
  })

  it('supports keyboard activation', async () => {
    const view = renderThemeSwitch()
    const button = view.getByLabelText('Dark Mode')

    expect(button).toBePartiallyChecked()

    button.focus()

    await view.events.keyboard('{Space}')

    expect(button).toBeChecked()

    await view.events.keyboard('{Space}')

    expect(button).not.toBeChecked()

    await view.events.keyboard('{Space}')

    expect(button).toBePartiallyChecked()
  })
})
