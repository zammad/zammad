// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { computed, ref } from 'vue'
import type { Except } from 'type-fest'

import type { ButtonVariant } from '#shared/types/button.ts'

export interface ConfirmationOptions {
  headerTitle?: string
  headerTitlePlaceholder?: string[]
  text: string
  textPlaceholder?: string[]
  buttonLabel?: string
  buttonVariant?: ButtonVariant
  confirmCallback: () => void
  cancelCallback: () => void
}

const confirmationOptions = ref<ConfirmationOptions>()
const showConfirmation = computed(() => !!confirmationOptions.value)

export const useConfirmation = () => {
  const waitForConfirmation = (
    text: string,
    options: Except<
      ConfirmationOptions,
      'text' | 'confirmCallback' | 'cancelCallback'
    > = {},
  ) => {
    return new Promise<boolean>((resolve) => {
      confirmationOptions.value = {
        ...options,
        text,
        confirmCallback() {
          resolve(true)
        },
        cancelCallback() {
          resolve(false)
        },
      }
    })
  }

  return {
    showConfirmation,
    confirmationOptions,
    waitForConfirmation,
  }
}
