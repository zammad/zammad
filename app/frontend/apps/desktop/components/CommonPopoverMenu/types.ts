// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { RequiredPermission } from '#shared/types/permission.ts'
import type { ObjectLike } from '#shared/types/utils.ts'

import { type Props as ItemProps } from './CommonPopoverMenuItem.vue'

import type { Component } from 'vue'

export type Variant = 'secondary' | 'danger'

export interface MenuItem extends ItemProps {
  key: string
  permission?: RequiredPermission
  show?: (entity?: ObjectLike) => boolean
  separatorTop?: boolean
  onClick?: (entity?: ObjectLike) => void
  noCloseOnClick?: boolean
  component?: Component
  variant?: Variant
}
