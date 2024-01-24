// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { UseElementBoundingReturn } from '@vueuse/core'
import type { Ref } from 'vue'

export interface FieldTreeSelectInputDropdownInstance {
  openDropdown(bounds: UseElementBoundingReturn, height: Ref<number>): void
  closeDropdown(): void
  getFocusableOptions(): HTMLElement[]
  moveFocusToDropdown(lastOption: boolean): void
  isOpen: boolean
}

export interface FieldTreeSelectInputDropdownInternalInstance
  extends Omit<FieldTreeSelectInputDropdownInstance, 'isOpen'> {
  isOpen: Ref<boolean>
}
