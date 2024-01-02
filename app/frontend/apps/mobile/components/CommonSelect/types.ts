// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { Ref } from 'vue'

export interface CommonSelectInstance {
  openDialog(): void
  closeDialog(): void
  getFocusableOptions(): HTMLElement[]
  isOpen: boolean
}

export interface CommonSelectInternalInstance
  extends Omit<CommonSelectInstance, 'isOpen'> {
  isOpen: Ref<boolean>
}
