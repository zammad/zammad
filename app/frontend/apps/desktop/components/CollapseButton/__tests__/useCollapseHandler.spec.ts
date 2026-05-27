// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { vi } from 'vitest'
import { shallowRef } from 'vue'

import renderComponent from '#tests/support/components/renderComponent.ts'

import { useCollapseHandler } from '#desktop/components/CollapseButton/useCollapseHandler.ts'

describe('useCollapseHandler', () => {
  it('starts not collapsed by default', () => {
    renderComponent({
      setup() {
        const { isCollapsed } = useCollapseHandler({ collapse: vi.fn(), expand: vi.fn() })
        expect(isCollapsed.value).toBe(false)
      },
      template: '<div/>',
    })
  })

  it('uses provided isCollapsed ref', () => {
    const collapsed = shallowRef(true)

    renderComponent({
      setup() {
        const { isCollapsed } = useCollapseHandler(
          { collapse: vi.fn(), expand: vi.fn() },
          { isCollapsed: collapsed },
        )
        expect(isCollapsed.value).toBe(true)
      },
      template: '<div/>',
    })
  })

  it('toggleCollapse without argument flips to collapsed and calls collapse callback', async () => {
    const callbacks = { collapse: vi.fn(), expand: vi.fn() }

    renderComponent({
      setup() {
        const { isCollapsed, toggleCollapse } = useCollapseHandler(callbacks)
        toggleCollapse()
        expect(isCollapsed.value).toBe(true)
        expect(callbacks.collapse).toHaveBeenCalledOnce()
        expect(callbacks.expand).not.toHaveBeenCalled()
      },
      template: '<div/>',
    })
  })

  it('toggleCollapse(true) collapses and calls collapse callback', async () => {
    const callbacks = { collapse: vi.fn(), expand: vi.fn() }

    renderComponent({
      setup() {
        const { isCollapsed, toggleCollapse } = useCollapseHandler(callbacks)
        toggleCollapse(true)
        expect(isCollapsed.value).toBe(true)
        expect(callbacks.collapse).toHaveBeenCalledOnce()
        expect(callbacks.expand).not.toHaveBeenCalled()
      },
      template: '<div/>',
    })
  })

  it('toggleCollapse(false) expands and calls expand callback', async () => {
    const collapsed = shallowRef(true)
    const callbacks = { collapse: vi.fn(), expand: vi.fn() }

    renderComponent({
      setup() {
        const { isCollapsed, toggleCollapse } = useCollapseHandler(callbacks, {
          isCollapsed: collapsed,
        })
        toggleCollapse(false)
        expect(isCollapsed.value).toBe(false)
        expect(callbacks.expand).toHaveBeenCalledOnce()
        expect(callbacks.collapse).not.toHaveBeenCalled()
      },
      template: '<div/>',
    })
  })
})
