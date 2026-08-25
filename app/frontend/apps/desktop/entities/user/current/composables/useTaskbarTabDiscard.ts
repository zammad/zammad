// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { useConfirmation } from '#shared/composables/useConfirmation.ts'
import { useWalker } from '#shared/router/walker.ts'

// Leaving a create view for good: go back first, then drop the tab - the other order navigates
//   away from under the walker.
//
// The delete function is passed in instead of taken from `useTaskbarTab()` here, which would
//   register a second dirty state watcher for the same tab.
export const useTaskbarTabDiscard = (deleteTaskbarTab: () => void) => {
  const walker = useWalker()
  const { waitForVariantConfirmation } = useConfirmation()

  const goBack = () => {
    walker.back('/')
  }

  const discardChanges = async () => {
    const confirm = await waitForVariantConfirmation('unsaved')
    if (!confirm) return

    goBack()
    deleteTaskbarTab()
  }

  return { goBack, discardChanges }
}
