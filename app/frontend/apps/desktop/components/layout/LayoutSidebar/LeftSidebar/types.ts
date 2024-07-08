// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { MenuItem } from '#desktop/components/CommonPopoverMenu/types.ts'

export interface AddMenuItem extends MenuItem {
  /**
   * 3 digits
   * @example 100 | 200 | 300
   * */
  order: number
}

export interface AdminMenuItem extends MenuItem, AddMenuItem {}
