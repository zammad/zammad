// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '@tests/support/components'
import CommonIcon from '../CommonIcon.vue'

describe('CommonIcon.vue', () => {
  it('renders icon', () => {
    const wrapper = renderComponent(CommonIcon, {
      props: { name: 'arrow-left' },
    })
    expect(wrapper.getByIconName('arrow-left')).toHaveClass('icon')
    expect(wrapper.getByIconName('arrow-left')).toHaveAttribute(
      'aria-label',
      'arrow-left',
    )
  })

  it('renders icon with animation', () => {
    const wrapper = renderComponent(CommonIcon, {
      props: { name: 'cog', animation: 'spin' },
    })
    expect(wrapper.getByIconName('cog')).toHaveClass('animate-spin')
  })

  it('renders icon with small size', () => {
    const wrapper = renderComponent(CommonIcon, {
      props: { name: 'cog', size: 'small' },
    })

    expect(wrapper.getByIconName('cog')).toHaveAttribute('width', '20')
    expect(wrapper.getByIconName('cog')).toHaveAttribute('height', '20')
  })

  it('renders a decorative icon', () => {
    const wrapper = renderComponent(CommonIcon, {
      props: { name: 'cog', decorative: true },
    })

    expect(wrapper.getByIconName('cog')).toHaveAttribute('aria-hidden', 'true')
    expect(wrapper.getByIconName('cog')).not.toHaveAttribute('aria-label')
  })

  it('triggers click handler of icon', async () => {
    const wrapper = renderComponent(CommonIcon, {
      props: { name: 'dashboard' },
    })

    await wrapper.events.click(wrapper.getByIconName('dashboard'))

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
