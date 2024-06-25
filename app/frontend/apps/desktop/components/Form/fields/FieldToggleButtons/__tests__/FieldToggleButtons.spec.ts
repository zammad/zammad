// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { getNode } from '@formkit/core'
import { FormKit } from '@formkit/vue'

import { renderComponent } from '#tests/support/components/index.ts'

const renderToggleButtonsField = (props: any = {}) => {
  return renderComponent(FormKit, {
    form: true,
    formField: true,
    props: {
      id: 'toggleButtons',
      type: 'toggleButtons',
      name: 'toggleButtons',
      label: 'Toggle Buttons',
      ...props,
    },
  })
}

describe('Form - Field - Toggle Buttons', () => {
  it('renders toggle buttons', async () => {
    const view = renderToggleButtonsField({
      options: [
        { value: 'example', label: 'Example' },
        { value: 'other', label: 'Other' },
        { value: 'last', label: 'Last', icon: 'sun' },
      ],
    })

    const node = getNode('toggleButtons')!

    const exampleButton = view.getByRole('tab', { name: 'Example' })

    expect(exampleButton).toBeInTheDocument()
    expect(exampleButton).not.toBeDisabled()
    expect(exampleButton).not.toHaveAttribute('aria-selected', 'true')

    await view.events.click(exampleButton)

    expect(exampleButton).toHaveAttribute('aria-selected', 'true')

    expect(node.context?.value).toEqual('example')

    expect(view.getByIconName('sun')).toBeInTheDocument()
  })
})
