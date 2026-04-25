// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { useLocalStorage } from '@vueuse/core'

import type { MilestoneKey, MilestonesHistoryRecords } from '#desktop/types/appUsage.ts'

export const useAppUsage = () => {
  const milestoneHistory = useLocalStorage<MilestonesHistoryRecords>(
    'app-usage-milestones-trigger-history',
    () => ({
      '1h': false,
      '5h': false,
      '20h': false,
    }),
  )

  const triggerMilestone = (key: MilestoneKey) => {
    milestoneHistory.value[key] = true
  }

  const resetMilestoneHistory = () => {
    milestoneHistory.value = {
      '1h': false,
      '5h': false,
      '20h': false,
    }
  }

  /*
   * Total usage counter in milliseconds
   */
  const totalAppUsageTime = useLocalStorage('app-usage-total-time', 0)

  const neverAskAgainForTimedFeedback = useLocalStorage(
    'beta-ui-feedback-never-ask-again-timed',
    false,
  )

  const setNeverAskAgainForTimedFeedback = (value = true) => {
    neverAskAgainForTimedFeedback.value = value
  }

  return {
    milestoneHistory,
    triggerMilestone,
    resetMilestoneHistory,
    totalAppUsageTime,
    neverAskAgainForTimedFeedback,
    setNeverAskAgainForTimedFeedback,
  }
}
