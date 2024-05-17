// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { whenever } from '@vueuse/shared'

import { useConfirmation } from '#shared/composables/useConfirmation.ts'

import { useDialog } from '../CommonDialog/useDialog.ts'

export const initializeConfirmationDialog = () => {
  const { showConfirmation } = useConfirmation()

  const confirmationDialog = useDialog({
    name: 'confirmation',
    component: () => import('./CommonConfirmationDialog.vue'),
  })

  whenever(showConfirmation, () => {
    confirmationDialog.open()
  })
}
