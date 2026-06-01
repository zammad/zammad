// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { waitFor } from '@testing-library/vue'

import { renderComponent } from '#tests/support/components/index.ts'

import CommonNavigationTabs from '#desktop/components/CommonTabs/CommonNavigationTabs/CommonNavigationTabs.vue'

describe('CommonNavigationTabs', () => {
  const tabs = [
    { label: 'Tab 1', key: 'tab-1', link: '/tickets/view/my_assigned' },
    { label: 'Tab 2', key: 'tab-2', link: '/tickets/view/all_unassigned' },
  ]

  it('renders the tabs as links', () => {
    const wrapper = renderComponent(CommonNavigationTabs, {
      router: true,
      props: { tabs },
    })

    expect(wrapper.getByRole('list')).toBeInTheDocument()
    expect(wrapper.getByRole('link', { name: 'Tab 1' })).toBeInTheDocument()
    expect(wrapper.getByRole('link', { name: 'Tab 2' })).toBeInTheDocument()
  })

  it('keeps the link focusable', () => {
    const wrapper = renderComponent(CommonNavigationTabs, {
      router: true,
      props: { tabs: [tabs[0]] },
    })

    expect(wrapper.getByRole('link', { name: 'Tab 1' })).toHaveAttribute('tabindex', '0')
  })

  it('marks the active tab with aria-current', () => {
    const wrapper = renderComponent(CommonNavigationTabs, {
      router: true,
      props: { tabs, modelValue: 'tab-2' },
    })

    expect(wrapper.getByRole('link', { name: 'Tab 2' })).toHaveAttribute('aria-current', 'page')
    expect(wrapper.getByRole('link', { name: 'Tab 1' })).not.toHaveAttribute('aria-current')
  })

  it('scrolls the active tab into centered view', async () => {
    const scrollIntoViewSpy = vi
      .spyOn(HTMLElement.prototype, 'scrollIntoView')
      .mockImplementation(() => {})

    renderComponent(CommonNavigationTabs, {
      router: true,
      props: { tabs, modelValue: 'tab-2', mode: 'scroll' },
    })

    await waitFor(() => {
      expect(scrollIntoViewSpy).toHaveBeenCalledWith(
        expect.objectContaining({
          inline: 'center',
        }),
      )
    })

    scrollIntoViewSpy.mockRestore()
  })

  it('emits the clicked tab key', async () => {
    const wrapper = renderComponent(CommonNavigationTabs, {
      router: true,
      props: { tabs },
    })

    await wrapper.events.click(wrapper.getByRole('link', { name: 'Tab 1' }))

    await waitFor(() => {
      expect(wrapper.emitted()['update:modelValue']?.at(-1)).toEqual(['tab-1'])
    })
  })
})
