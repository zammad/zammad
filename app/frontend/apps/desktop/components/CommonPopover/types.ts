// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { Ref, Component } from 'vue'

import type { RequiredPermission } from '#shared/types/permission.ts'

import { type Props as ItemProps } from './CommonPopoverMenuItem.vue'

export interface CommonPopoverInstance {
  openPopover(): void
  closePopover(isInteractive?: boolean): void
  togglePopover(isInteractive?: boolean): void
  isOpen: boolean
}

export interface CommonPopoverInternalInstance
  extends Omit<CommonPopoverInstance, 'isOpen'> {
  isOpen: Ref<boolean>
}

export type Orientation =
  | 'top'
  | 'bottom'
  | 'left'
  | 'right'
  | 'autoVertical'
  | 'autoHorizontal'

export type Placement = 'start' | 'end'

export interface MenuItem extends ItemProps {
  key: string
  permission?: RequiredPermission
  show?: () => boolean
  separatorTop?: boolean
  onClick?(event: MouseEvent): void
  noCloseOnClick?: boolean
  component?: Component
}
