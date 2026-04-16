// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { acceptHMRUpdate, defineStore } from 'pinia'
import { computed } from 'vue'

import { initializeBetaUi } from '#desktop/components/BetaUi/composables/useBetaUi.ts'
import { useBetaUiFeedbackConsentState } from '#desktop/components/BetaUi/composables/useBetaUiFeedbackConsentState.ts'
import { useAppUsage } from '#desktop/composables/BetaUi/useAppUsage.ts'
import { useTimeTracker } from '#desktop/composables/BetaUi/useTimeTracker.ts'
import type { MilestoneKey } from '#desktop/types/appUsage.ts'

const MILESTONES = [
  { key: '1h', milliseconds: 60 * 60 * 1000 }, // 1 hour
  { key: '5h', milliseconds: 5 * 60 * 60 * 1000 }, // 5 hours
  { key: '20h', milliseconds: 20 * 60 * 60 * 1000 }, // 20 hours
] as const

export const useAppUsageStore = defineStore('appUsage', () => {
  const {
    milestoneHistory,
    triggerMilestone,
    totalAppUsageTime,
    neverAskAgainForTimedFeedback,
    setNeverAskAgainForTimedFeedback,
  } = useAppUsage()

  const updateTotalUsage = (millisecondsCount: number) => {
    if (typeof totalAppUsageTime.value !== 'number') totalAppUsageTime.value = 0

    totalAppUsageTime.value += millisecondsCount
  }

  const { hasFeedbackConsent } = useBetaUiFeedbackConsentState()
  const { switchValue, betaUiSwitchAvailable } = initializeBetaUi()

  useTimeTracker(updateTotalUsage, {
    enabled: () =>
      !!betaUiSwitchAvailable.value && !!switchValue.value && hasFeedbackConsent.value === 'true',
  })

  const currentMilestoneKey = computed<MilestoneKey | null>(() => {
    const total = typeof totalAppUsageTime.value === 'number' ? totalAppUsageTime.value : 0

    // ES2023 would be cleaner here
    // const milestone = MILESTONES.findLast((milestone) => milestone.milliseconds <= total)
    const milestone = [...MILESTONES].reverse().find((m) => m.milliseconds <= total)

    return milestone?.key ?? null
  })

  const shouldTriggerMilestoneDialog = computed(() => {
    if (!currentMilestoneKey.value || !hasFeedbackConsent.value) return false

    return (
      !milestoneHistory.value[currentMilestoneKey.value] && !neverAskAgainForTimedFeedback.value
    )
  })

  return {
    totalAppUsageTime: computed(() => totalAppUsageTime.value),
    triggeredMilestones: computed(() => milestoneHistory.value),
    triggerMilestone,
    currentMilestoneKey,
    shouldTriggerMilestoneDialog,
    setNeverAskAgainForTimedFeedback,
  }
})

if (import.meta.hot) {
  import.meta.hot.accept(acceptHMRUpdate(useAppUsageStore, import.meta.hot))
}
