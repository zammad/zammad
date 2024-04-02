// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { Ref } from 'vue'

import type { RequiredPermission } from '#shared/types/permission.ts'

import { type Props as ItemProps } from './CommonPopoverMenuItem.vue'

export interface CommonPopoverInstance {
  openPopover(): void
  closePopover(): void
  togglePopover(): void
  isOpen: boolean
}

export interface CommonPopoverInternalInstance
  extends Omit<CommonPopoverInstance, 'isOpen'> {
  isOpen: Ref<boolean>
}

export type Oritentation =
  | 'top'
  | 'bottom'
  | 'left'
  | 'right'
  | 'autoVertical'
  | 'autoHorizontal'

export type ArrowPlacement = 'start' | 'end'

export interface MenuItem extends ItemProps {
  key: string
  permission?: RequiredPermission
  seperatorTop?: boolean
  onClick?(event: MouseEvent): void
}
