// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { useLocalStorage } from '@vueuse/core'
import { computed, toRef } from 'vue'

import { useConfirmation } from '#shared/composables/useConfirmation.ts'
import { useApplicationStore } from '#shared/stores/application.ts'
import { useSessionStore } from '#shared/stores/session.ts'

import { useAppUsage } from '#desktop/composables/BetaUi/useAppUsage.ts'

import { EnumFeedbackDialog, useFeedbackDialog } from '../FeedbackDialog/useFeedbackDialog.ts'

import { useBetaUiFeedbackConsentState } from './useBetaUiFeedbackConsentState.ts'

export const initializeBetaUi = () => {
  const user = toRef(useSessionStore(), 'user')

  const config = toRef(useApplicationStore(), 'config')

  const { resetTotalAppUsageTime, setNeverAskAgainForTimedFeedback, resetMilestoneHistory } =
    useAppUsage()

  const betaUiSwitchAvailable = computed(
    () => config.value?.ui_desktop_beta_switch && user.value?.hasBetaUiSwitchAvailable,
  )

  const switchValue = useLocalStorage('beta-ui-switch', false)

  const clearSwitchAndRedirect = (redirectTo: string) => {
    switchValue.value = undefined

    window.location.href = redirectTo

    resetTotalAppUsageTime()
    setNeverAskAgainForTimedFeedback(false)
    resetMilestoneHistory()
  }

  return { switchValue, clearSwitchAndRedirect, betaUiSwitchAvailable, user }
}

export const useBetaUi = () => {
  const { switchValue, clearSwitchAndRedirect, betaUiSwitchAvailable, user } = initializeBetaUi()
  const dismissValue = useLocalStorage('beta-ui-switch-dismiss', false)

  const betaUiSwitchEnabled = computed(() => betaUiSwitchAvailable.value && !dismissValue.value)

  const { hasFeedbackConsent } = useBetaUiFeedbackConsentState()

  const { openFeedbackDialog } = useFeedbackDialog(EnumFeedbackDialog.SwitchBack)

  const clearFeedbackConsentAndRedirect = (redirectTo: string) => {
    hasFeedbackConsent.value = undefined

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
