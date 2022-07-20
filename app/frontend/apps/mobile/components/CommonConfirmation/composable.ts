// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { Ref, ref } from 'vue'
import { ConfirmationOptions } from './types'

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
