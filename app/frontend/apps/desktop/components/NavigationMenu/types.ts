// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { RouteRecordRaw } from 'vue-router'

export type NavigationMenuCategory = {
  label: string
  icon?: string
  id: string
  order: number
  collapsed?: boolean
}

export type NavigationMenuEntry = {
  label: string
  icon?: string
  iconColor?: string
  count?: string | number
  keywords?: string
  route: (RouteRecordRaw & { name: string }) | string
  show?: () => boolean
}

export enum NavigationMenuDensity {
  Comfortable = 'comfortable',
  Dense = 'dense',
}
