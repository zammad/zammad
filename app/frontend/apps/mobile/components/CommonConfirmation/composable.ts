// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { Ref } from 'vue'
import { ref } from 'vue'
import type { ConfirmationOptions } from './types'

const confirmationDialog: Ref<ConfirmationOptions | undefined> = ref()

const useConfirmation = () => {
  const showConfirmation = (confirmationOptions: ConfirmationOptions) => {
    confirmationDialog.value = confirmationOptions
  }

  const waitForConfirmation = (
    heading: string,
    options: Pick<
      ConfirmationOptions,
      'buttonTextColorClass' | 'buttonTitle' | 'headingPlaceholder'
    > = {},
  ) => {
    return new Promise<boolean>((resolve) => {
      showConfirmation({
        ...options,
        heading,
        confirmCallback() {
          resolve(true)
        },
        cancelCallback() {
          resolve(false)
        },
      })
    })
  }

  return {
    confirmationDialog,
    showConfirmation,
    waitForConfirmation,
  }
}

export default useConfirmation
