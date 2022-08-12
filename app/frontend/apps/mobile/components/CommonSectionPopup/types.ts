// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

export interface PopupItem {
  label: string
  link?: string
  class?: string
  onAction?(): void
}
