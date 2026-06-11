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

import { useSidebarDisplay } from '#desktop/components/layout/useSidebarDisplay.ts'

import { SidebarName } from '../types.ts'

describe('useSidebarDisplay', () => {
  beforeEach(async () => {
    initializeStore()

    isSmallScreen.value = false
    await nextTick()

    useSidebarDisplay(SidebarName.Primary).toggleSidebar(false)

    isSmallScreen.value = true
    await nextTick()

    useSidebarDisplay(SidebarName.Primary).toggleSidebar(false)

    isSmallScreen.value = false
    await nextTick()
  })

  it('remembers collapse state on large screens', () => {
    const { isSidebarCollapsed: primarySidebar, toggleSidebar } = useSidebarDisplay(
      SidebarName.Primary,
    )

    expect(primarySidebar.value).toBe(false)

    toggleSidebar(true)

    expect(primarySidebar.value).toBe(true)

    const secondPrimarySidebar = useSidebarDisplay(SidebarName.Primary)

    expect(secondPrimarySidebar.isSidebarCollapsed.value).toBe(true)
  })

  it('keeps small-screen collapse state independent from large screens', async () => {
    const { isSidebarCollapsed: primarySidebar, toggleSidebar } = useSidebarDisplay(
      SidebarName.Primary,
    )

    expect(primarySidebar.value).toBe(false)

    toggleSidebar(true)

    expect(primarySidebar.value).toBe(true)

    isSmallScreen.value = true
    await nextTick()

    expect(primarySidebar.value).toBe(true)

    toggleSidebar(false)
    expect(primarySidebar.value).toBe(false)

    isSmallScreen.value = false
    await nextTick()

    expect(primarySidebar.value).toBe(true)
  })
})
