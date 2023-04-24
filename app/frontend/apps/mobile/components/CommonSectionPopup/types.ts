// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { ButtonVariant } from '#shared/components/Form/fields/FieldButton/types.ts'

export interface PopupItem {
  label: string
  link?: string
  class?: string
  buttonVariant?: ButtonVariant
  attributes?: Record<string, unknown>
  onAction?(): void
  noHideOnSelect?: boolean
}
