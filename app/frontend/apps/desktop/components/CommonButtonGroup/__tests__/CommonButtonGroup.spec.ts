// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { getByIconName } from '#tests/support/components/iconQueries.ts'
import { renderComponent } from '#tests/support/components/index.ts'

import CommonButtonGroup from '../CommonButtonGroup.vue'

import type { CommonButtonItem } from '../types.ts'

const onActionClick = vi.fn()

const items: CommonButtonItem[] = [
  {
    label: 'Button 1',
    variant: 'primary',
    icon: 'logo-flat',
    onActionClick,
  },
  {
    label: 'Button 2',
    variant: 'secondary',
  },
  {
    label: 'Button 3',
    variant: 'tertiary',
  },
  {
    label: 'Button 4',
    variant: 'submit',
    type: 'submit',
  },
  {
    label: 'Button 5',
    variant: 'danger',
    size: 'large',
  },
]

describe('CommonButtonGroup.vue', () => {
  it('renders buttons with correct classes, types, ...', async () => {
    const view = renderComponent(CommonButtonGroup, {
      props: {
        items,
      },
    })

    const buttons = view.getAllByRole('button')
    expect(buttons).toHaveLength(5)

    const primaryButton = buttons[0]
    expect(primaryButton).toHaveAttribute('type', 'button')
    expect(primaryButton).toHaveClasses(['bg-blue-800', 'bg-blue-800'])
    expect(getByIconName(primaryButton, 'logo-flat')).toBeInTheDocument()

    await view.events.click(primaryButton)
    expect(onActionClick).toHaveBeenCalledOnce()

    const submitButton = buttons[3]
    expect(submitButton).toHaveAttribute('type', 'submit')

    const dangerButton = buttons[4]
    expect(dangerButton).toHaveClasses(['bg-pink-100', 'text-red-500'])
  })
})
