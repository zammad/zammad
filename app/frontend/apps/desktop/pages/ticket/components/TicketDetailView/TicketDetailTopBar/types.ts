// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { MenuItem } from '#desktop/components/CommonPopoverMenu/types.ts'

export interface MenuState {
  activeMenuItem: MenuItem
  isActive: boolean
  isEraserActive: boolean
}

export type MenuStateUpdate = Partial<MenuState>
