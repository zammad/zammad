// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { mount } from '@vue/test-utils'
import { beforeEach, vi } from 'vitest'
import { nextTick } from 'vue'

import { useCollapseHandler } from '#desktop/components/CollapseButton/composables/useCollapseHandler.ts'

describe('useCollapseHandler', async () => {
  const emit = vi.fn()

  beforeEach(() => {
    localStorage.clear()
  })

  it('initializes with collapsed state from local storage', async () => {
    const TestComponent = {
      setup() {
        const { isCollapsed } = useCollapseHandler(emit, { storageKey: 'test' })
        expect(isCollapsed.value).toBe(false)
      },
      template: '<div></div>',
    }
    mount(TestComponent)
  })

  it('sync local storage state on initial load', async () => {
    localStorage.setItem('test', 'true')
    const TestComponent = {
      setup() {
        const { isCollapsed } = useCollapseHandler(emit, { storageKey: 'test' })
        expect(isCollapsed.value).toBe(true)
      },
      template: '<div></div>',
    }
    mount(TestComponent)
    await nextTick()
    expect(emit).toHaveBeenCalledWith('collapse', true)
  })

  it('calls expand if collapse state is false', async () => {
    const TestComponent = {
      setup() {
        const { toggleCollapse } = useCollapseHandler(emit, {
          storageKey: 'test',
        })
        toggleCollapse()
      },
      template: '<div></div>',
    }

    mount(TestComponent)
    await nextTick()
    expect(emit).toHaveBeenCalledWith('collapse', true)
  })
})
