// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { ref } from 'vue'

import type { ButtonVariant } from '#shared/types/button.ts'
import getUuid from '#shared/utils/getUuid.ts'

import { useAppName } from './useAppName.ts'

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
  hideCancelButton?: boolean
  fullscreen?: boolean
  // TODO: should maybe also be implemented for mobile, so that we have a better alignment for the code
  confirmationVariant?: ConfirmationVariant
  confirmCallback: () => void
  cancelCallback: () => void
  closeCallback: () => void
}

const confirmationOptions = ref(new Map<string, ConfirmationOptions>())
const lastConfirmationUuid = ref<string | undefined>()
const triggerConfirmation = ref(0)

export const useConfirmation = () => {
  const appName = useAppName()

  const waitForConfirmation = (
    text: string,
    options: Except<
      ConfirmationOptions,
      'text' | 'confirmCallback' | 'cancelCallback' | 'closeCallback'
    > = {},
    name: string | undefined = undefined,
  ) => {
    const uniqueName =
      appName === 'desktop' ? name || getUuid() : 'confirmation'

    if (confirmationOptions.value.has(uniqueName)) {
      return new Promise<undefined>((resolve) => {
        resolve(undefined)
      })
    }

    return new Promise<boolean | undefined>((resolve) => {
      confirmationOptions.value.set(uniqueName, {
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
      })

      lastConfirmationUuid.value = uniqueName
      triggerConfirmation.value += 1
    })
  }

  const waitForVariantConfirmation = (
    variant: ConfirmationVariant = 'confirm',
    options: Except<
      ConfirmationOptions,
      'text' | 'confirmCallback' | 'cancelCallback' | 'closeCallback'
    > = {},
    name: string | undefined = undefined,
  ) => {
    return waitForConfirmation(
      '',
      {
        ...options,
        confirmationVariant: variant,
      },
      name,
    )
  }

  return {
    lastConfirmationUuid,
    triggerConfirmation,
    confirmationOptions,
    waitForConfirmation,
    waitForVariantConfirmation,
  }
}
