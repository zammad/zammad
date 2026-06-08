// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { Link } from '#shared/types/router.ts'

import type { MaybeRefOrGetter } from 'vue'
export interface Tab {
  label: string
  /**
   * If a tab controls a tab panel
   * On 'role=tabpanel' add -> aria-labelledby=`tab-label-${tab.key}`
   * On 'role=tabpanel' add -> id=`tab-panel-${tab.key}`
   */
  key: string
  disabled?: boolean
  /**
   * Should be set to single tab in a tab group
   * Defaults otherwise to first tab in group
   */
  default?: boolean
  icon?: string
  tooltip?: string
  count?: number | string
  classes?: {
    badge?: string
  }
}

export interface NavigationTab extends Tab {
  link: Link
}

export interface MarkerStyle {
  top: string
  left: string
  width: string
  height: string
  // just due missing type compatibility to CSSProperties and  StyleValue
  [key: `--${string}`]: string
}

export interface TabsScrollListClasses {
  container: string
  item: string
  tab: string
  marker: string
}

export interface TabsOverflowMenuClasses {
  container: string
  item: string
  tab: string
  tabActive: string
  overflowButton: string
  overflowButtonActive: string
  menuItem: string
  overflowItem: string
  overflowItemActive: string
}

export interface TabsOptions {
  tabs: MaybeRefOrGetter<Tab[]>
  /**
   * Keys of the currently active tab(s). The first one positions the marker pill.
   */
  activeKeys: MaybeRefOrGetter<Tab['key'][]>
  /**
   * Whether the strip draws the sliding marker pill (single tabs / navigation, not multiselect).
   */
  hasMarker: MaybeRefOrGetter<boolean>
}

export type TabBaseProps<T extends Tab> = Omit<T, 'key'> & {
  tabId: T['key']
  size: 'medium' | 'large'
  activeKeys: T['key'][]
}
