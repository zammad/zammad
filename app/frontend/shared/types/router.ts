// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import type { EnumTaskbarEntity } from '#shared/graphql/types.ts'

import type { RequiredPermission } from './permission.ts'
import type { App } from 'vue'
import type {
  Router,
  RouteRecordRaw,
  RouteLocationRaw,
  RouteLocationNormalizedGeneric,
} from 'vue-router'

export type InitializeAppRouter = (app: App) => Router

export interface RoutesModule {
  isMainRoute: boolean
  default: Array<RouteRecordRaw> | RouteRecordRaw
}

export interface RouteRecordMeta {
  title?: string
  requiresAuth: boolean
  requiredPermission: Maybe<RequiredPermission>
  redirectToDefaultRoute?: boolean
  hasBottomNavigation?: boolean
  customBottomNavigation?: boolean
  hasHeader?: boolean
  hasOwnLandmarks?: boolean
  taskbarTabEntity?: EnumTaskbarEntity
  taskbarTabEntityKey?: string
  isTaskbarTabPossible?: (route: RouteLocationNormalizedGeneric) => boolean
  level?: number
  pageKey?: string
  permanentItem?: boolean
}

export type Link = RouteLocationRaw
