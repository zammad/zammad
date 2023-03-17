// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { App } from 'vue'
import type { Router, RouteRecordRaw, RouteLocationRaw } from 'vue-router'
import type { RequiredPermission } from './permission'

export type InitializeAppRouter = (app: App) => Router

export interface RoutesModule {
  isMainRoute: boolean
  default: Array<RouteRecordRaw> | RouteRecordRaw
}

export interface RouteRecordMeta {
  title?: string
  requiresAuth: boolean
  requiredPermission: Maybe<RequiredPermission>
  hasBottomNavigation?: boolean
  customBottomNavigation?: boolean
  hasHeader?: boolean
  hasOwnLandmarks?: boolean
  level?: number
}

export type Link = RouteLocationRaw
