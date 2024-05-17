// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { isRef } from 'vue'

import {
  useResizeGridColumns,
  DEFAULT_SIDEBAR_WIDTH,
  SIDEBAR_COLLAPSED_WIDTH,
} from '../useResizeGridColumns.ts'

describe('useResizeGridColumns', () => {
  const {
    gridColumns,
    isSidebarCollapsed,
    resizeSidebar,
    collapseSidebar,
    expandSidebar,
    resetSidebarWidth,
  } = useResizeGridColumns('testKey-123')
  test('gridColumns and isSidebarCollapsed are reactive', () => {
    expect(isRef(gridColumns)).toBe(true)
    expect(isRef(isSidebarCollapsed)).toBe(true)
  })
  test('initial state', () => {
    expect(isSidebarCollapsed.value).toBe(false)
    expect(gridColumns.value).toEqual({
      gridTemplateColumns: `${DEFAULT_SIDEBAR_WIDTH}px 1fr`,
    })
  })
  test('collapseSidebar', () => {
    collapseSidebar()
    expect(isSidebarCollapsed.value).toBe(true)
    expect(gridColumns.value).toEqual({
      gridTemplateColumns: `${SIDEBAR_COLLAPSED_WIDTH}px 1fr`,
    })
  })
  test('expandSidebar', () => {
    expandSidebar()
    expect(isSidebarCollapsed.value).toBe(false)
    expect(gridColumns.value).toEqual({
      gridTemplateColumns: `${DEFAULT_SIDEBAR_WIDTH}px 1fr`,
    })
  })
  test('resizeSidebar', () => {
    resizeSidebar(300)
    expect(gridColumns.value).toEqual({ gridTemplateColumns: '300px 1fr' })
  })
  test('resetSidebarWidth', () => {
    resetSidebarWidth()
    expect(gridColumns.value).toEqual({
      gridTemplateColumns: `${DEFAULT_SIDEBAR_WIDTH}px 1fr`,
    })
  })
  it('persists state in local storage if storageKey is provided', () => {
    expect(localStorage.getItem('testKey-123-sidebar-width')).toBeTruthy()
  })
  it('does not persist state if storageKey is not provided', () => {
    localStorage.clear()
    useResizeGridColumns()
    expect(localStorage.getItem('testKey-123-sidebar-width')).toBeNull()
  })
})
