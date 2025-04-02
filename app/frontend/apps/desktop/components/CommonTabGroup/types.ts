// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

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
  count?: number
}
