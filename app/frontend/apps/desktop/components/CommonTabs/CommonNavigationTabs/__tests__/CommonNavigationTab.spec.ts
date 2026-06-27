// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'

import CommonNavigationTab from '#desktop/components/CommonTabs/CommonNavigationTabs/CommonNavigationTab.vue'

describe('CommonNavigationTab', () => {
  const baseProps = {
    link: '/tickets/view/my_assigned',
    label: 'Tab 1',
    size: 'medium' as const,
    tabId: 'tab-1',
    activeKeys: ['tab-1'],
  }

  it('renders passed label as link text', () => {
    const wrapper = renderComponent(CommonNavigationTab, {
      router: true,
      props: baseProps,
    })

    expect(wrapper.getByRole('link', { name: 'Tab 1' })).toBeInTheDocument()
  })

  it('renders passed count', () => {
    const wrapper = renderComponent(CommonNavigationTab, {
      router: true,
      props: {
        ...baseProps,
        count: 99,
      },
    })

    expect(wrapper.getByText('99')).toBeInTheDocument()
  })

  it('renders passed icon', () => {
    const wrapper = renderComponent(CommonNavigationTab, {
      router: true,
      props: {
        ...baseProps,
        icon: 'search',
      },
    })

    expect(wrapper.getByIconName('search')).toBeInTheDocument()
  })

  it('marks the link as current when it is active', () => {
    const wrapper = renderComponent(CommonNavigationTab, {
      router: true,
      props: {
        ...baseProps,
        activeKeys: ['tab-1'],
      },
    })

    expect(wrapper.getByRole('link', { name: 'Tab 1' })).toHaveAttribute('aria-current', 'page')
  })

  it('does not mark the link as current when it is inactive', () => {
    const wrapper = renderComponent(CommonNavigationTab, {
      router: true,
      props: {
        ...baseProps,
        activeKeys: ['tab-2'],
      },
    })

    expect(wrapper.getByRole('link', { name: 'Tab 1' })).not.toHaveAttribute('aria-current')
  })

  it('emits "select" on click', async () => {
    const wrapper = renderComponent(CommonNavigationTab, {
      router: true,
      props: baseProps,
    })

    await wrapper.events.click(wrapper.getByRole('link', { name: 'Tab 1' }))

    expect(wrapper.emitted().select).toHaveLength(1)
  })

  it('does not emit "select" when disabled', async () => {
    const wrapper = renderComponent(CommonNavigationTab, {
      router: true,
      props: {
        ...baseProps,
        disabled: true,
      },
    })

    await wrapper.events.click(wrapper.getByRole('link', { name: 'Tab 1' }))

    expect(wrapper.emitted().select).toBeUndefined()
  })
})
