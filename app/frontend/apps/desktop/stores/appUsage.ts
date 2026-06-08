// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { useLocalStorage } from '@vueuse/core'
import { acceptHMRUpdate, defineStore } from 'pinia'
import { computed, toRef } from 'vue'

import { useApplicationStore } from '#shared/stores/application.ts'
import { useSessionStore } from '#shared/stores/session.ts'

import { useBetaUiFeedbackConsentState } from '#desktop/components/BetaUi/composables/useBetaUiFeedbackConsentState.ts'
import { useTimeTracker } from '#desktop/composables/BetaUi/useTimeTracker.ts'
import type { MilestoneKey, MilestonesHistoryRecords } from '#desktop/types/appUsage.ts'

const MILESTONES = [
  { key: '1h', milliseconds: 60 * 60 * 1000 }, // 1 hour
  { key: '5h', milliseconds: 5 * 60 * 60 * 1000 }, // 5 hours
  { key: '20h', milliseconds: 20 * 60 * 60 * 1000 }, // 20 hours
] as const

export const useAppUsageStore = defineStore('appUsage', () => {
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

  const totalAppUsageTime = useLocalStorage('app-usage-total-time', 0)

  const resetTotalAppUsageTime = () => {
    totalAppUsageTime.value = 0
  }

  const neverAskAgainForTimedFeedback = useLocalStorage(
    'beta-ui-feedback-never-ask-again-timed',
    false,
  )

  const setNeverAskAgainForTimedFeedback = (value = true) => {
    neverAskAgainForTimedFeedback.value = value
  }

  const switchValue = useLocalStorage('beta-ui-switch', false)
  const dismissValue = useLocalStorage('beta-ui-switch-dismiss', false)

  const user = toRef(useSessionStore(), 'user')
  const config = toRef(useApplicationStore(), 'config')

  const betaUiSwitchAvailable = computed(
    () => config.value?.ui_desktop_beta_switch && user.value?.hasBetaUiSwitchAvailable,
  )

  const { hasFeedbackConsent } = useBetaUiFeedbackConsentState()

  const updateTotalUsage = (millisecondsCount: number) => {
    if (typeof totalAppUsageTime.value !== 'number') totalAppUsageTime.value = 0

    totalAppUsageTime.value += millisecondsCount
  }

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
    switchValue,
    dismissValue,
    betaUiSwitchAvailable,
    neverAskAgainForTimedFeedback: computed(() => neverAskAgainForTimedFeedback.value),
    setNeverAskAgainForTimedFeedback,
    totalAppUsageTime: computed(() => totalAppUsageTime.value),
    triggeredMilestones: computed(() => milestoneHistory.value),
    triggerMilestone,
    resetMilestoneHistory,
    resetTotalAppUsageTime,
    currentMilestoneKey,
    shouldTriggerMilestoneDialog,
  }
})

if (import.meta.hot) {
  import.meta.hot.accept(acceptHMRUpdate(useAppUsageStore, import.meta.hot))
}
