// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { ButtonVariant } from '#shared/components/Form/fields/FieldButton/types.ts'

export interface ConfirmationOptions {
  heading: string
  headingPlaceholder?: string[]
  buttonTitle?: string
  buttonVariant?: ButtonVariant
  confirmCallback: () => void
  cancelCallback?: () => void
}
