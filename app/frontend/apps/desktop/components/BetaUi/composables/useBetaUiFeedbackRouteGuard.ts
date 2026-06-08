// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { storeToRefs } from 'pinia'
import { useRouter } from 'vue-router'

import { useAppUsageStore } from '#desktop/stores/appUsage.ts'

import { useFeedbackDialog } from '../FeedbackDialog/useFeedbackDialog.ts'

export const useBetaUiFeedbackRouteGuard = () => {
  const { openFeedbackDialog } = useFeedbackDialog()
  const appUsageStore = useAppUsageStore()
  const { shouldTriggerMilestoneDialog, currentMilestoneKey } = storeToRefs(appUsageStore)

  useRouter().beforeEach((_, from) => {
    // Initial navigation, or coming from login page are ignored.
    if (!from.name || from.name === 'Login' || !shouldTriggerMilestoneDialog.value) return

    const milestone = currentMilestoneKey.value ?? undefined

    openFeedbackDialog({ milestone })

    if (milestone) appUsageStore.triggerMilestone(milestone)
  })
}
