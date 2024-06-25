// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { Ref } from 'vue'

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

export type Placement = 'start' | 'arrowStart' | 'arrowEnd' | 'end'

export type Variant = 'secondary' | 'danger'
