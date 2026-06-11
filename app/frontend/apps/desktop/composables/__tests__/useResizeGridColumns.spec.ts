// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { isRef, nextTick, ref } from 'vue'

import { initializeStore } from '#tests/support/components/initializeStore.ts'

import { useSidebarDisplayStore } from '#desktop/components/layout/stores/sidebarDisplay.ts'
import { SidebarPosition, SidebarName } from '#desktop/components/layout/types.ts'

import {
  useResizeGridColumns,
  DEFAULT_START_SIDEBAR_WIDTH,
  DEFAULT_END_SIDEBAR_WIDTH,
  MINIMUM_END_SIDEBAR_WIDTH,
  MINIMUM_START_SIDEBAR_WIDTH,
  SIDEBAR_COLLAPSED_WIDTH,
} from '../useResizeGridColumns.ts'

const smallScreen = ref(false)
const isSmallestScreen = ref(false)

vi.mock('#desktop/composables/responsiveness/useAppBreakpoints.ts', () => ({
  useAppBreakpoints: () => ({
    isSmallScreen: smallScreen,
    isSmallestScreen,
  }),
}))

describe('useResizeGridColumns', () => {
  initializeStore()

  const { gridColumns, minSidebarWidth, resizeSidebar, resetSidebarWidth } = useResizeGridColumns(
    SidebarName.Primary,
  )

  beforeEach(() => {
    useSidebarDisplayStore().setCollapsed(SidebarName.Primary, false)
    resetSidebarWidth()
  })

  test('gridColumns is reactive', () => {
    expect(isRef(gridColumns)).toBe(true)
  })

  test('initial state', () => {
    expect(useSidebarDisplayStore().persistedCollapsed[SidebarName.Primary]).toBe(false)
    expect(useSidebarDisplayStore().sessionCollapsed[SidebarName.Primary]).toBe(false)

    expect(gridColumns.value).toEqual({
      gridTemplateColumns: `${DEFAULT_START_SIDEBAR_WIDTH}px 1fr`,
    })
  })

  test('collapsed state', () => {
    useSidebarDisplayStore().setCollapsed(SidebarName.Primary, true)

    expect(gridColumns.value).toEqual({
      gridTemplateColumns: `${SIDEBAR_COLLAPSED_WIDTH}px 1fr`,
    })
  })

  test('expanded state', () => {
    useSidebarDisplayStore().setCollapsed(SidebarName.Primary, false)

    expect(gridColumns.value).toEqual({
      gridTemplateColumns: `${DEFAULT_START_SIDEBAR_WIDTH}px 1fr`,
    })
  })

  test('resizeSidebar', () => {
    resizeSidebar(300)

    expect(gridColumns.value).toEqual({ gridTemplateColumns: '300px 1fr' })
  })

  test('resetSidebarWidth', () => {
    resizeSidebar(300)
    resetSidebarWidth()

    expect(gridColumns.value).toEqual({
      gridTemplateColumns: `${DEFAULT_START_SIDEBAR_WIDTH}px 1fr`,
    })
  })

  it('persists width in local storage', () => {
    expect(localStorage.getItem(`${SidebarName.Primary}-sidebar-width`)).toBeTruthy()
  })

  it('defaults to start position (left)', () => {
    expect(gridColumns.value).toEqual({
      gridTemplateColumns: `${DEFAULT_START_SIDEBAR_WIDTH}px 1fr`,
    })

    expect(minSidebarWidth).toEqual(MINIMUM_START_SIDEBAR_WIDTH)
  })

  it('supports end position (right)', () => {
    const { gridColumns, minSidebarWidth } = useResizeGridColumns(
      SidebarName.TicketContent,
      SidebarPosition.End,
    )

    expect(gridColumns.value).toEqual({
      gridTemplateColumns: `1fr ${DEFAULT_END_SIDEBAR_WIDTH}px`,
    })

    expect(minSidebarWidth).toEqual(MINIMUM_END_SIDEBAR_WIDTH)
  })

  it('uses default width on small screens and restores previous persisted width on large screens', async () => {
    localStorage.setItem(`${SidebarName.Primary}-sidebar-width`, '312')

    const { gridColumns, resizeSidebar } = useResizeGridColumns(SidebarName.Primary)

    expect(gridColumns.value).toEqual({ gridTemplateColumns: '312px 1fr' })

    smallScreen.value = true
    await nextTick()

    expect(gridColumns.value).toEqual({
      gridTemplateColumns: `${DEFAULT_START_SIDEBAR_WIDTH}px 1fr`,
    })

    resizeSidebar(330)

    expect(localStorage.getItem(`${SidebarName.Primary}-sidebar-width`)).toEqual('312')
    expect(gridColumns.value).toEqual({
      gridTemplateColumns: `${DEFAULT_START_SIDEBAR_WIDTH}px 1fr`,
    })

    smallScreen.value = false
    await nextTick()

    expect(gridColumns.value).toEqual({ gridTemplateColumns: '312px 1fr' })
  })
})
