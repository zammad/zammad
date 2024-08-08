// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { onBeforeRouteLeave, onBeforeRouteUpdate } from 'vue-router'

import { useConfirmation } from '#shared/composables/useConfirmation.ts'

export const useAbortNavigation = ({
  confirmCallback,
  shouldConfirmNavigation,
}: {
  confirmCallback: () => void
  shouldConfirmNavigation: () => boolean
}) => {
  const { waitForVariantConfirmation } = useConfirmation()

  onBeforeRouteUpdate(async () => {
    if (!shouldConfirmNavigation()) return true

    const confirmed = await waitForVariantConfirmation('unsaved')

    if (confirmed) {
      confirmCallback()
      return true
    }

    return false
  })

  onBeforeRouteLeave(async () => {
    if (!shouldConfirmNavigation()) return true

    const confirmed = await waitForVariantConfirmation('unsaved')

    if (confirmed) {
      confirmCallback()
      return true
    }
    return false
  })
}
