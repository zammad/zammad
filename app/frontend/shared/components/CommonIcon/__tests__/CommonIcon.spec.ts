// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'

import CommonIcon from '../CommonIcon.vue'

describe('CommonIcon.vue', () => {
  it('renders icon', () => {
    const wrapper = renderComponent(CommonIcon, {
      props: { name: 'chevron-left' },
    })
    expect(wrapper.getByIconName('chevron-left')).toHaveClass('icon')
    expect(wrapper.getByIconName('chevron-left')).toHaveAttribute(
      'aria-label',
      'chevron-left',
    )
  })

  it('renders icon with animation', () => {
    const wrapper = renderComponent(CommonIcon, {
      props: { name: 'settings', animation: 'spin' },
    })
    expect(wrapper.getByIconName('settings')).toHaveClass('animate-spin')
  })

  it('renders icon with small size', () => {
    const wrapper = renderComponent(CommonIcon, {
      props: { name: 'settings', size: 'small' },
    })

    expect(wrapper.getByIconName('settings')).toHaveAttribute('width', '20')
    expect(wrapper.getByIconName('settings')).toHaveAttribute('height', '20')
  })

  it('renders a decorative icon', () => {
    const wrapper = renderComponent(CommonIcon, {
      props: { name: 'settings', decorative: true },
    })

    expect(wrapper.getByIconName('settings')).toHaveAttribute(
      'aria-hidden',
      'true',
    )
    expect(wrapper.getByIconName('settings')).not.toHaveAttribute('aria-label')
  })

  it('triggers click handler of icon', async () => {
    const wrapper = renderComponent(CommonIcon, {
      props: { name: 'puzzle' },
    })

    await wrapper.events.click(wrapper.getByIconName('puzzle'))

    expect(wrapper.emitted().click).toHaveLength(1)
  })

  it('provides a label for assistive technologies', async () => {
    const wrapper = renderComponent(CommonIcon, {
      props: { name: 'logo' },
    })

    expect(wrapper.getByIconName('logo')).toHaveAccessibleName('logo')

    await wrapper.rerender({
      label: 'Product Logo',
    })

    expect(wrapper.getByIconName('logo')).toHaveAccessibleName('Product Logo')
  })
})
