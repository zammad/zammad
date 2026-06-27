// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { nextTick, ref } from 'vue'

const isSmallScreen = ref(false)

vi.mock('#desktop/composables/responsiveness/useAppBreakpoints.ts', () => ({
  useAppBreakpoints: () => ({
    isSmallScreen,
    isSmallestScreen: ref(false),
  }),
}))

import { initializeStore } from '#tests/support/components/initializeStore.ts'

import { useSidebarDisplayStore } from '#desktop/components/layout/stores/sidebarDisplay.ts'

import { SidebarName } from '../../types.ts'

describe('sidebarDisplay store', () => {
  beforeEach(async () => {
    initializeStore()
    localStorage.clear()

    isSmallScreen.value = false
    await nextTick()

    useSidebarDisplayStore().setCollapsed(SidebarName.Primary, false)
  })

  it('keeps persisted and session collapse state separate across breakpoint switches', async () => {
    const store = useSidebarDisplayStore()

    expect(store.currentCollapsed[SidebarName.Primary]).toBe(false)

    store.setCollapsed(SidebarName.Primary, true)

    expect(store.persistedCollapsed[SidebarName.Primary]).toBe(true)
    expect(store.sessionCollapsed[SidebarName.Primary]).toBe(false)
    expect(store.currentCollapsed[SidebarName.Primary]).toBe(true)

    isSmallScreen.value = true
    await nextTick()

    expect(store.currentCollapsed[SidebarName.Primary]).toBe(true)

    store.setCollapsed(SidebarName.Primary, false)

    expect(store.persistedCollapsed[SidebarName.Primary]).toBe(true)
    expect(store.sessionCollapsed[SidebarName.Primary]).toBe(false)
    expect(store.currentCollapsed[SidebarName.Primary]).toBe(false)

    isSmallScreen.value = false
    await nextTick()

    expect(store.currentCollapsed[SidebarName.Primary]).toBe(true)
  })
})
