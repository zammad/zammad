// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { isRef } from 'vue'

import { SidebarPosition } from '#desktop/components/layout/types.ts'
import { isSidebarCollapsed, SidebarName } from '#desktop/components/layout/useSidebarDisplay.ts'

import {
  useResizeGridColumns,
  DEFAULT_START_SIDEBAR_WIDTH,
  DEFAULT_END_SIDEBAR_WIDTH,
  MINIMUM_END_SIDEBAR_WIDTH,
  MINIMUM_START_SIDEBAR_WIDTH,
  SIDEBAR_COLLAPSED_WIDTH,
} from '../useResizeGridColumns.ts'

describe('useResizeGridColumns', () => {
  const { gridColumns, minSidebarWidth, resizeSidebar, resetSidebarWidth } = useResizeGridColumns(
    SidebarName.Primary,
  )

  beforeEach(() => {
    isSidebarCollapsed[SidebarName.Primary].value = false
    resetSidebarWidth()
  })

  test('gridColumns is reactive', () => {
    expect(isRef(gridColumns)).toBe(true)
  })

  test('initial state', () => {
    expect(isSidebarCollapsed[SidebarName.Primary].value).toBe(false)

    expect(gridColumns.value).toEqual({
      gridTemplateColumns: `${DEFAULT_START_SIDEBAR_WIDTH}px 1fr`,
    })
  })

  test('collapsed state', () => {
    isSidebarCollapsed[SidebarName.Primary].value = true

    expect(gridColumns.value).toEqual({
      gridTemplateColumns: `${SIDEBAR_COLLAPSED_WIDTH}px 1fr`,
    })
  })

  test('expanded state', () => {
    isSidebarCollapsed[SidebarName.Primary].value = false

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
})
