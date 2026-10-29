// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { UseElementBoundingReturn } from '@vueuse/core'
import type { Ref, ShallowRef, UnwrapRef } from 'vue'

export interface CommonPopoverInstance {
  openPopover(): void
  openPopoverDelayed(): void
  closePopover(isInteractive?: boolean): void
  togglePopover(isInteractive?: boolean): void
  cancelOpenPopover(): void
  isOpen: boolean
  popoverElement: HTMLDivElement | null
}

export interface CommonPopoverInternalInstance extends Omit<
  CommonPopoverInstance,
  'isOpen' | 'popoverElement'
> {
  isOpen: Ref<boolean>
  popoverElement: Readonly<ShallowRef<HTMLDivElement | null>>
}

export type Orientation = 'top' | 'bottom' | 'left' | 'right' | 'autoVertical' | 'autoHorizontal'

export type Placement = 'start' | 'arrowStart' | 'arrowEnd' | 'end'

export type TargetElementBounds = UnwrapRef<UseElementBoundingReturn>
