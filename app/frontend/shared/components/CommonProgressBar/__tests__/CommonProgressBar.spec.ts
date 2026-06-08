// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'

import CommonProgressBar from '../CommonProgressBar.vue'

describe('CommonProgressBar.vue', () => {
  it('renders an indeterminate progress bar by default', async () => {
    const wrapper = renderComponent(CommonProgressBar)

    const progressBar = wrapper.getByRole('progressbar')

    expect(progressBar).toHaveAttribute('tabindex', '0')
    expect(progressBar).toHaveAttribute('aria-label', 'Indicating progress')
    expect(progressBar).not.toHaveAttribute('value')
    expect(progressBar).not.toHaveAttribute('max')
  })

  it('renders given value and max attributes', async () => {
    const wrapper = renderComponent(CommonProgressBar, {
      props: {
        value: '50',
        max: '100',
      },
    })

    const progressBar = wrapper.getByRole('progressbar')

    expect(progressBar).toHaveAttribute('value', '50')
    expect(progressBar).toHaveAttribute('max', '100')
  })

  it('applies small size class', async () => {
    const wrapper = renderComponent(CommonProgressBar, {
      props: {
        size: 'small',
      },
    })

    const progressBar = wrapper.getByRole('progressbar')

    expect(progressBar).toHaveClass('h-1')
    expect(progressBar).not.toHaveClass('h-2')
  })

  it('applies normal size class when passed explicitly', async () => {
    const wrapper = renderComponent(CommonProgressBar, {
      props: {
        size: 'normal',
      },
    })

    const progressBar = wrapper.getByRole('progressbar')

    expect(progressBar).toHaveClass('h-2')
    expect(progressBar).not.toHaveClass('h-1')
  })

  it('renders value without max when only value is provided', async () => {
    const wrapper = renderComponent(CommonProgressBar, {
      props: {
        value: '12',
      },
    })

    const progressBar = wrapper.getByRole('progressbar')

    expect(progressBar).toHaveAttribute('value', '12')
    expect(progressBar).not.toHaveAttribute('max')
  })

  it('renders max without value when only max is provided', async () => {
    const wrapper = renderComponent(CommonProgressBar, {
      props: {
        max: '250',
      },
    })

    const progressBar = wrapper.getByRole('progressbar')

    expect(progressBar).toHaveAttribute('max', '250')
    expect(progressBar).not.toHaveAttribute('value')
  })

  describe('variant classes', () => {
    it('applies primary variant class by default', () => {
      const wrapper = renderComponent(CommonProgressBar)

      expect(wrapper.getByRole('progressbar')).toHaveClass('progress-bar--primary')
      expect(wrapper.getByRole('progressbar')).not.toHaveClass('progress-bar--inverted')
    })

    it('applies primary variant class when set explicitly', () => {
      const wrapper = renderComponent(CommonProgressBar, {
        props: { variant: 'primary' },
      })

      expect(wrapper.getByRole('progressbar')).toHaveClass('progress-bar--primary')
      expect(wrapper.getByRole('progressbar')).not.toHaveClass('progress-bar--inverted')
    })

    it('applies inverted variant class', () => {
      const wrapper = renderComponent(CommonProgressBar, {
        props: { variant: 'inverted' },
      })

      expect(wrapper.getByRole('progressbar')).toHaveClass('progress-bar--inverted')
      expect(wrapper.getByRole('progressbar')).not.toHaveClass('progress-bar--primary')
    })
  })
})
