// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'

import CommonProgressBar from '../CommonProgressBar.vue'

describe('CommonProgressBar.vue', () => {
  it('renders a progress bar with indeterminate state', async () => {
    const view = renderComponent(CommonProgressBar)

    const progressBar = view.getByRole('progressbar')
    expect(progressBar).toHaveClass('progress')
    expect(progressBar).not.toHaveAttribute('value')
    expect(progressBar).not.toHaveAttribute('max')
  })

  it('renders a progress bar with given value + max', async () => {
    const view = renderComponent(CommonProgressBar, {
      props: {
        value: '50',
        max: '100',
      },
    })

    const progressBar = view.getByRole('progressbar')
    expect(progressBar).toHaveClass('progress')
    expect(progressBar).toHaveAttribute('value', '50')
    expect(progressBar).toHaveAttribute('max', '100')
  })
})
