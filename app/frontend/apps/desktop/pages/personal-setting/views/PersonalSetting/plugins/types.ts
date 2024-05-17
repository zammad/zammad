// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { NavigationMenuCategory } from '#desktop/components/NavigationMenu/types.ts'

import type { RouteRecordRaw } from 'vue-router'

export interface PersonalSettingPlugin {
  label: string
  category: NavigationMenuCategory
  route: RouteRecordRaw & { name: string }
  order: number
  keywords: string
  show?: () => boolean
}
