// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '@tests/support/components'
import CommonIcon from '../CommonIcon.vue'

describe('CommonIcon.vue', () => {
  it('renders icon', () => {
    const wrapper = renderComponent(CommonIcon, {
      props: { name: 'arrow-left' },
    })
    expect(wrapper.getByIconName('arrow-left')).toHaveClass('icon')
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
  })
  it('triggers click handler of icon', async () => {
    const wrapper = renderComponent(CommonIcon, {
      props: { name: 'dashboard' },
    })

    await wrapper.events.click(wrapper.getByIconName('dashboard'))

    expect(wrapper.emitted().click).toHaveLength(1)
  })
})
