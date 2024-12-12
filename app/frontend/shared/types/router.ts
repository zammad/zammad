// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { EnumTaskbarEntity } from '#shared/graphql/types.ts'

import type { RequiredPermission } from './permission.ts'
import type { App } from 'vue'
import type { Router, RouteRecordRaw, RouteLocationRaw } from 'vue-router'

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
  level?: number
  pageKey?: string
  permanentItem?: boolean
}

export type Link = RouteLocationRaw
