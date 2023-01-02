// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

export interface PopupItem {
  label: string
  link?: string
  class?: string
  onAction?(): void
}
