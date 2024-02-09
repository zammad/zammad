// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type {
  ButtonSize,
  ButtonType,
  ButtonVariant,
} from '#desktop/components/CommonButton/types.ts'

export interface CommonButtonItem {
  variant?: ButtonVariant
  type?: ButtonType
  size?: ButtonSize
  label: string
  labelPlaceholder?: string[]
  disabled?: boolean
  hidden?: boolean
  icon?: string
  onActionClick?: () => void
}
