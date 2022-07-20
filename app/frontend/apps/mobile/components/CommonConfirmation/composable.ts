// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { Ref } from 'vue'
import { ref } from 'vue'
import type { ConfirmationOptions } from './types'

const confirmationDialog: Ref<ConfirmationOptions | undefined> = ref()

const useConfirmation = () => {
  const showConfirmation = (confirmationOptions: ConfirmationOptions) => {
    confirmationDialog.value = confirmationOptions
  }

  return {
    confirmationDialog,
    showConfirmation,
  }
}

export default useConfirmation
