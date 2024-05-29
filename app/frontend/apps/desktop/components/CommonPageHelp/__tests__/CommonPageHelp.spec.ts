// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { beforeAll } from 'vitest'

import { renderComponent } from '#tests/support/components/index.ts'

import CommonPageHelp from '../CommonPageHelp.vue'

const renderPageHelp = (options: any = {}) => {
  return renderComponent(CommonPageHelp, {
    ...options,
    dialog: true,
  })
}

describe('CommonPageHelp.vue', () => {
  beforeAll(() => {
    const main = document.createElement('main')
    main.id = 'page-main-content'
    document.body.appendChild(main)
  })

  afterAll(() => {
    document.body.innerHTML = ''
  })

  it('show help button', async () => {
    const view = renderPageHelp({
      slots: {
        default: () => 'A help example.',
      },
    })

    expect(view.getByRole('button', { name: 'Help' })).toBeInTheDocument()
    expect(view.getByIconName('question-circle')).toBeInTheDocument()
  })

  it('opens help dialog', async () => {
    const view = renderPageHelp({
      slots: {
        default: () => 'A help example.',
      },
    })

    await view.events.click(view.getByRole('button', { name: 'Help' }))

    expect(await view.findByRole('dialog')).toBeInTheDocument()
    expect(await view.findByText('A help example.')).toBeInTheDocument()
  })
})
