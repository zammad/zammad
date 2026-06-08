// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { UserData } from '#shared/types/store.ts'

import type { RouteRecordRaw } from 'vue-router'

export type NavigationMenuCategory = {
  label: string
  icon?: string
  id: string
  order: number
  collapsed?: boolean
}

export type NavigationMenuEntry = {
  id?: string
  label: string
  title?: string
  icon?: string
  iconColor?: string
  count?: string | number
  keywords?: string
  route: (RouteRecordRaw & { name: string }) | string
  show?: (currentUser?: Maybe<UserData>) => boolean
}

export enum NavigationMenuDensity {
  Comfortable = 'comfortable',
  Dense = 'dense',
}
