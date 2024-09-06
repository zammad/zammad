// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { computed, ref } from 'vue'

import type { ButtonVariant } from '#shared/types/button.ts'

import type { Except } from 'type-fest'

export type ConfirmationVariant = 'delete' | 'unsaved' | 'confirm'

export interface ConfirmationOptions {
  headerTitle?: string
  headerTitlePlaceholder?: string[]
  headerIcon?: string
  text?: string
  textPlaceholder?: string[]
  buttonLabel?: string
  buttonVariant?: ButtonVariant
  cancelLabel?: string
  // TODO: should maybe also be implemented for mobile, so that we have a better alignment for the code
  confirmationVariant?: ConfirmationVariant
  confirmCallback: () => void
  cancelCallback: () => void
  closeCallback: () => void
}

const confirmationOptions = ref<ConfirmationOptions>()
const showConfirmation = computed(() => !!confirmationOptions.value)

export const useConfirmation = () => {
  const waitForConfirmation = (
    text: string,
    options: Except<
      ConfirmationOptions,
      'text' | 'confirmCallback' | 'cancelCallback' | 'closeCallback'
    > = {},
  ) => {
    return new Promise<boolean | undefined>((resolve) => {
      confirmationOptions.value = {
        ...options,
        text,
        confirmCallback() {
          resolve(true)
        },
        cancelCallback() {
          resolve(false)
        },
        closeCallback() {
          resolve(undefined)
        },
      }
    })
  }

  const waitForVariantConfirmation = (
    variant: ConfirmationVariant = 'confirm',
    options: Except<
      ConfirmationOptions,
      'text' | 'confirmCallback' | 'cancelCallback' | 'closeCallback'
    > = {},
  ) => {
    return waitForConfirmation('', {
      ...options,
      confirmationVariant: variant,
    })
  }

  return {
    showConfirmation,
    confirmationOptions,
    waitForConfirmation,
    waitForVariantConfirmation,
  }
}
