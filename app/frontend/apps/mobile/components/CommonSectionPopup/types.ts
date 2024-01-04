// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { TooltipItemDescriptor } from '#shared/components/CommonTooltip/types.ts'
import type { ButtonVariant } from '#shared/components/Form/fields/FieldButton/types.ts'

export interface PopupItemDescriptor extends TooltipItemDescriptor {
  link?: string
  class?: string
  buttonVariant?: ButtonVariant
  attributes?: Record<string, unknown>
  onAction?(): void
  noHideOnSelect?: boolean
}
