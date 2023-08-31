// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { ref } from 'vue'
import type { ButtonVariant } from '#shared/components/Form/fields/FieldButton/types.ts'

export interface ConfirmationOptions {
  heading: string
  headingPlaceholder?: string[]
  buttonTitle?: string
  buttonVariant?: ButtonVariant
  confirmCallback: () => void
  cancelCallback?: () => void
}

export const confirmationOptions = ref<ConfirmationOptions>()

export const waitForConfirmation = (
  heading: string,
  options: Pick<
    ConfirmationOptions,
    'buttonTitle' | 'buttonVariant' | 'headingPlaceholder'
  > = {},
) => {
  return new Promise<boolean>((resolve) => {
    confirmationOptions.value = {
      ...options,
      heading,
      confirmCallback() {
        resolve(true)
      },
      cancelCallback() {
        resolve(false)
      },
    }
  })
}
