// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { ButtonVariant } from '#shared/components/Form/fields/FieldButton/types.ts'

export type ButtonType = 'button' | 'reset' | 'submit'
export type ButtonSize = 'small' | 'medium'

export interface CommonButtonProps {
  prefixIcon?: string
  icon?: string
  suffixIcon?: string
  form?: string
  type?: ButtonType
  size?: ButtonSize
  disabled?: boolean
  variant?: ButtonVariant
  transparentBackground?: boolean
}
