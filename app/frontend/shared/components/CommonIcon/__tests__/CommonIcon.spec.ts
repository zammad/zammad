// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '@tests/support/components'
import CommonIcon from '../CommonIcon.vue'

describe('CommonIcon.vue', () => {
  it('renders icon', () => {
    const wrapper = renderComponent(CommonIcon, {
      props: { name: 'mobile-chevron-left' },
    })
    expect(wrapper.getByIconName('mobile-chevron-left')).toHaveClass('icon')
    expect(wrapper.getByIconName('mobile-chevron-left')).toHaveAttribute(
      'aria-label',
      'mobile-chevron-left',
    )
  })

  it('renders icon with animation', () => {
    const wrapper = renderComponent(CommonIcon, {
      props: { name: 'mobile-settings', animation: 'spin' },
    })
    expect(wrapper.getByIconName('mobile-settings')).toHaveClass('animate-spin')
  })

  it('renders icon with small size', () => {
    const wrapper = renderComponent(CommonIcon, {
      props: { name: 'mobile-settings', size: 'small' },
    })

    expect(wrapper.getByIconName('mobile-settings')).toHaveAttribute(
      'width',
      '20',
    )
    expect(wrapper.getByIconName('mobile-settings')).toHaveAttribute(
      'height',
      '20',
    )
  })

  it('renders a decorative icon', () => {
    const wrapper = renderComponent(CommonIcon, {
      props: { name: 'mobile-settings', decorative: true },
    })

    expect(wrapper.getByIconName('mobile-settings')).toHaveAttribute(
      'aria-hidden',
      'true',
    )
    expect(wrapper.getByIconName('mobile-settings')).not.toHaveAttribute(
      'aria-label',
    )
  })

  it('triggers click handler of icon', async () => {
    const wrapper = renderComponent(CommonIcon, {
      props: { name: 'mobile-puzzle' },
    })

    await wrapper.events.click(wrapper.getByIconName('mobile-puzzle'))

    expect(wrapper.emitted().click).toHaveLength(1)
  })

  it('provides a label for assistive technologies', async () => {
    const wrapper = renderComponent(CommonIcon, {
      props: { name: 'mobile-logo' },
    })

    expect(wrapper.getByIconName('mobile-logo')).toHaveAccessibleName(
      'mobile-logo',
    )

    await wrapper.rerender({
      label: 'Product Logo',
    })

    expect(wrapper.getByIconName('mobile-logo')).toHaveAccessibleName(
      'Product Logo',
    )
  })
})
