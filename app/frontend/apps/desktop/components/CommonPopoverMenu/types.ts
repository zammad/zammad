// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { ButtonVariant } from '#shared/types/button.ts'
import type { RequiredPermission } from '#shared/types/permission.ts'
import type { ObjectLike } from '#shared/types/utils.ts'

import { type Props as ItemProps } from './CommonPopoverMenuItem.vue'

import type { Component, ComputedRef } from 'vue'
import type { Router } from 'vue-router'

export type Variant = ButtonVariant

export interface MenuItem extends ItemProps {
  key: string
  permission?: RequiredPermission
  show?: (entity?: ObjectLike) => boolean
  /**
   * Same group labels will be grouped together in the popover menu.
   * Adds a separator between groups by default.
   */
  groupLabel?: string
  separatorTop?: boolean
  onClick?: (entity?: ObjectLike, router?: Router) => void
  noCloseOnClick?: boolean
  component?: Component
  variant?: Variant
  /**
   * Shows Label when used in single action mode.
   */
  showLabel?: boolean
}

export interface UsePopoverMenuReturn {
  filteredMenuItems: ComputedRef<MenuItem[] | undefined>
  singleMenuItemPresent: ComputedRef<boolean>
  singleMenuItem: ComputedRef<MenuItem | undefined>
}

export interface GroupItem {
  groupLabel: string
  key: string
  array: MenuItem[]
}

export type MenuItems = Array<MenuItem | GroupItem>
