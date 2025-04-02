// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

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
        label: 'Avatar skeleton',
      })

      // eslint-disable-next-line @typescript-eslint/ban-ts-comment
      // @ts-expect-error
      expect(wrapper.getByRole('progressbar'), {
        busy: true,
        name: 'Avatar skeleton',
        value: {
          min: 0,
          max: 100,
          text: 'Please wait until content is loaded',
        },
      }).toBeInTheDocument()
    })
  })
})
