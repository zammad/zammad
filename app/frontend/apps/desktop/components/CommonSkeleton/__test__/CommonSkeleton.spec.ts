// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { expect } from 'vitest'

import { renderComponent } from '#tests/support/components/index.ts'

import CommonSkeleton from '#desktop/components/CommonSkeleton/CommonSkeleton.vue'

describe('CommonSkeleton', () => {
  it('renders CommonSkeleton', () => {
    const wrapper = renderComponent(CommonSkeleton)

    expect(wrapper.getByRole('progressbar')).toHaveClass('animate-pulse')
  })

  it('supports to make the skeleton completly round', () => {
    const wrapper = renderComponent(CommonSkeleton, {
      props: { rounded: true },
    })
    expect(wrapper.getByRole('progressbar')).toHaveClass('rounded-full')
  })

  describe('a11y', () => {
    it('should have no accessibility violations', async () => {
      const wrapper = renderComponent(CommonSkeleton, {
        props: {
          label: 'Avatar skeleton',
        },
      })

      const progressBar = wrapper.getByRole('progressbar', {
        name: 'Avatar skeleton',
        busy: true,
      })

      expect(progressBar).toHaveAttribute('aria-valuemin', '0')
      expect(progressBar).toHaveAttribute('aria-valuemax', '100')
      expect(progressBar).toHaveAttribute('aria-valuetext', 'Please wait until content is loaded')
    })
  })
})
