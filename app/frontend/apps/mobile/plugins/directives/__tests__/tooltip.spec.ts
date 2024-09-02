// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { waitFor } from '@testing-library/vue'
import { describe } from 'vitest'

import renderComponent from '#tests/support/components/renderComponent.ts'

describe('Shared TooltipDirective', () => {
  it('adds aria label without showing tooltip', async () => {
    const wrapper = renderComponent({
      template: `
          <div v-tooltip="'Hello, Tooltip'">Foo Test World</div>
         `,
    })

    expect(wrapper.getByLabelText('Hello, Tooltip')).toBeInTheDocument()

    await wrapper.events.hover(wrapper.getByText('Foo Test World'))
    await waitFor(() =>
      expect(wrapper.queryByText('Hello, Tooltip')).not.toBeInTheDocument(),
    )
  })
})
