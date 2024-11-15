// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'

import CommonDivider from '../CommonDivider.vue'

describe('CommonDivider.vue', () => {
  it('renders with default prop values', async () => {
    const view = renderComponent(CommonDivider)

    expect(view.getByRole('separator')).toHaveClasses(['w-full', 'h-px'])
  })

  it('supports vertical orientation', async () => {
    const view = renderComponent(CommonDivider, {
      props: {
        orientation: 'vertical',
      },
    })

    expect(view.getByRole('separator')).toHaveClasses(['w-px', 'h-full'])
  })

  it('supports padding prop', async () => {
    const view = renderComponent(CommonDivider, {
      props: {
        padding: true,
      },
    })

    const container = view.getByRole('separator').parentElement

    expect(container).toHaveClass('px-2.5')

    await view.rerender({
      orientation: 'vertical',
    })

    expect(container).not.toHaveClass('px-2.5')
    expect(container).toHaveClass('py-2.5')
  })

  it('supports alternative background prop', async () => {
    const view = renderComponent(CommonDivider, {
      props: {
        alternativeBackground: true,
      },
    })

    const separator = view.getByRole('separator')

    expect(separator).toHaveClasses(['bg-white', 'dark:bg-gray-200'])

    await view.rerender({
      alternativeBackground: false,
    })

    expect(separator).toHaveClasses(['bg-neutral-100', 'dark:bg-gray-900'])
  })
})
