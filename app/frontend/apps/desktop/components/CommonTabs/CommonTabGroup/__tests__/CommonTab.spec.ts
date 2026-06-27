// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { describe } from 'vitest'

import { renderComponent } from '#tests/support/components/index.ts'

import CommonTab from '#desktop/components/CommonTabs/CommonTabGroup/CommonTab.vue'

describe('CommonTab', () => {
  it('renders passed label', () => {
    const wrapper = renderComponent(CommonTab, {
      props: {
        label: 'foo',
        size: 'medium',
        tabId: 'foo',
        activeKeys: ['foo'],
      },
    })

    expect(wrapper.getByText('foo')).toBeInTheDocument()
  })

  it('renders passed count', () => {
    const wrapper = renderComponent(CommonTab, {
      props: {
        label: 'foo',
        size: 'medium',
        tabId: 'foo',
        activeKeys: ['foo'],
        count: 99,
      },
    })

    expect(wrapper.getByText('99')).toBeInTheDocument()
  })

  it('renders passed icon', () => {
    const wrapper = renderComponent(CommonTab, {
      props: {
        label: 'foo',
        size: 'medium',
        tabId: 'foo',
        activeKeys: ['foo'],
        icon: 'search',
      },
    })

    expect(wrapper.getByIconName('search')).toBeInTheDocument()
  })

  // normally classes are not tested but in this case as we have no other reliable way
  it('applies responsive label classes when icon-only display is allowed', () => {
    const wrapper = renderComponent(CommonTab, {
      props: {
        label: 'foo',
        size: 'medium',
        tabId: 'foo',
        activeKeys: ['foo'],
        icon: 'search',
        canDisplayIconOnly: true,
      },
    })

    expect(wrapper.getByText('foo')).toHaveClass('sr-only', '@lg:not-sr-only')
  })

  describe('button mode', () => {
    it('renders a tab by default', () => {
      const wrapper = renderComponent(CommonTab, {
        props: {
          label: 'foo',
          size: 'medium',
          activeKeys: ['foo'],
          tabId: 'foo',
        },
      })

      expect(wrapper.getByRole('tab', { name: 'foo' })).toBeInTheDocument()
    })

    it('renders an option in multiple mode', () => {
      const wrapper = renderComponent(CommonTab, {
        props: {
          label: 'foo',
          size: 'medium',
          tabId: 'foo',
          activeKeys: ['foo'],
          multiple: true,
        },
      })

      expect(wrapper.getByRole('option', { name: 'foo' })).toBeInTheDocument()
    })

    it('marks the tab as selected when it is active', () => {
      const wrapper = renderComponent(CommonTab, {
        props: {
          label: 'foo',
          size: 'medium',
          tabId: 'foo',
          activeKeys: ['foo'],
        },
      })

      expect(wrapper.getByRole('tab', { name: 'foo' })).toHaveAttribute('aria-selected', 'true')
    })

    it('marks the tab as not selected when it is inactive', () => {
      const wrapper = renderComponent(CommonTab, {
        props: {
          label: 'foo',
          size: 'medium',
          tabId: 'foo',
          activeKeys: ['bar'],
        },
      })

      expect(wrapper.getByRole('tab', { name: 'foo' })).toHaveAttribute('aria-selected', 'false')
    })

    it('emits "select" on click', async () => {
      const wrapper = renderComponent(CommonTab, {
        props: {
          label: 'foo',
          size: 'medium',
          activeKeys: ['foo'],
          tabId: 'foo',
        },
      })

      await wrapper.events.click(wrapper.getByRole('tab', { name: 'foo' }))

      expect(wrapper.emitted().select).toHaveLength(1)
    })

    it('does not emit "select" when disabled', async () => {
      const wrapper = renderComponent(CommonTab, {
        props: {
          label: 'foo',
          size: 'medium',
          tabId: 'foo',
          activeKeys: [],
          disabled: true,
        },
      })

      await wrapper.events.click(wrapper.getByRole('tab', { name: 'foo' }))

      expect(wrapper.emitted().select).toBeUndefined()
    })
  })
})
