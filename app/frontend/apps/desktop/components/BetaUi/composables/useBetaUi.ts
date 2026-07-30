// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { storeToRefs } from 'pinia'
import { computed, toRef } from 'vue'

import { useConfirmation } from '#shared/composables/useConfirmation.ts'
import { useSessionStore } from '#shared/stores/session.ts'

import { useAppUsageStore } from '#desktop/stores/appUsage.ts'

import { EnumFeedbackDialog, useFeedbackDialog } from '../FeedbackDialog/useFeedbackDialog.ts'

import { useBetaUiFeedbackConsentState } from './useBetaUiFeedbackConsentState.ts'

export const initializeBetaUi = () => {
  const appUsage = useAppUsageStore()
  const { switchValue, betaUiSwitchAvailable } = storeToRefs(appUsage)

  const clearSwitch = () => {
    switchValue.value = null

    appUsage.setNeverAskAgainForTimedFeedback(false)
    appUsage.resetMilestoneHistory()
    appUsage.resetTotalAppUsageTime()
  }

  const clearSwitchAndRedirect = (redirectTo: string) => {
    clearSwitch()

    window.location.href = redirectTo
  }

  return { switchValue, clearSwitch, clearSwitchAndRedirect, betaUiSwitchAvailable }
}

export const useBetaUi = () => {
  const { switchValue, clearSwitchAndRedirect, betaUiSwitchAvailable } = initializeBetaUi()

  const { dismissValue } = storeToRefs(useAppUsageStore())
  const user = toRef(useSessionStore(), 'user')

  const betaUiSwitchEnabled = computed(() => betaUiSwitchAvailable.value && !dismissValue.value)

  const { hasFeedbackConsent } = useBetaUiFeedbackConsentState()

  const { openFeedbackDialog } = useFeedbackDialog(EnumFeedbackDialog.SwitchBack)

  const clearFeedbackConsentAndRedirect = (redirectTo: string) => {
    hasFeedbackConsent.value = null

    clearSwitchAndRedirect(redirectTo)
  }

  const toggleBetaUiSwitch = (redirectTo = '/', skipFeedback = false) => {
    if (skipFeedback) {
      clearSwitchAndRedirect(redirectTo)
      return
    }

    if (hasFeedbackConsent.value !== 'true') {
      clearFeedbackConsentAndRedirect(redirectTo)
      return
    }

    openFeedbackDialog({
      callback: () => {
        clearFeedbackConsentAndRedirect(redirectTo)
      },
    })
  }

  const dismissBetaUiSwitch = () => {
    const { waitForConfirmation } = useConfirmation()

    waitForConfirmation(
      __(
        'You can switch between the old and the New BETA UI at any moment in the Profile settings > New BETA UI section.',
      ),
      {
        headerIcon: 'question-circle',
        headerTitle: __('Help'),
        buttonLabel: __('Got it'),
        hideCancelButton: true,
        fullscreen: true,
      },
      `beta-ui-dismiss-${user.value?.id}`,
    )

    dismissValue.value = true
  }

  const toggleDismissBetaUiSwitch = () => {
    dismissValue.value = !dismissValue.value
  }

  return {
    betaUiSwitchAvailable,
    betaUiSwitchEnabled,
    hasFeedbackConsent,
    switchValue,
    dismissValue,
    toggleBetaUiSwitch,
    dismissBetaUiSwitch,
    toggleDismissBetaUiSwitch,
  }
}
