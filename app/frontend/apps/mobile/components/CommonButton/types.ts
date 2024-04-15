// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { ButtonVariant } from '#shared/components/Form/fields/FieldButton/types.ts'

export interface CommonButtonProps {
  form?: string
  type?: 'button' | 'reset' | 'submit'
  disabled?: boolean
  variant?: ButtonVariant
  transparentBackground?: boolean
}
