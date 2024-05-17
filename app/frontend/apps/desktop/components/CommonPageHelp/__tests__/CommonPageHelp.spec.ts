// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'

import CommonPageHelp from '../CommonPageHelp.vue'

const renderPageHelp = (
  props: Record<string, unknown> = {},
  options: any = {},
) => {
  return renderComponent(CommonPageHelp, {
    props,
    ...options,
    dialog: true,
  })
}

describe('CommonPageHelp.vue', () => {
  it('show help button', async () => {
    const view = renderPageHelp({
      slots: {
        default: 'A help example.',
      },
    })

    expect(view.getByRole('button', { name: 'Help' })).toBeInTheDocument()

    // TODO ...
  })

  // TODO ...
})
