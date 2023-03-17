// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

export interface CommonSelectInstance {
  openDialog(): void
  closeDialog(): void
  getFocusableOptions(): HTMLElement[]
  isOpen: boolean
}
