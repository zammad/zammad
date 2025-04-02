// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { useLocalStorage } from '@vueuse/core'
import { storeToRefs } from 'pinia'
import { computed } from 'vue'

import { useConfirmation } from '#shared/composables/useConfirmation.ts'
import { useApplicationStore } from '#shared/stores/application.ts'
import { useSessionStore } from '#shared/stores/session.ts'
import hasPermission from '#shared/utils/hasPermission.ts'

export const useNewBetaUi = () => {
  const { user } = storeToRefs(useSessionStore())
  const { config } = storeToRefs(useApplicationStore())

  const switchValue = useLocalStorage('beta-ui-switch', false)

  const dismissValue = useLocalStorage('beta-ui-switch-dismiss', false)

  const betaUiSwitchEnabled = computed(
    () =>
      config.value.ui_desktop_beta_switch &&
      hasPermission(
        'user_preferences.beta_ui_switch',
        user.value?.permissions?.names ?? [],
      ) &&
      !dismissValue.value,
  )

  const toggleBetaUiSwitch = (redirectTo = '/') => {
    switchValue.value = undefined

    window.location.href = redirectTo
  }

  const dismissBetaUiSwitch = () => {
    const { waitForConfirmation } = useConfirmation()

    waitForConfirmation(
      __(
        'You can switch between the old and the New BETA UI at any moment in the Profile Settings > New BETA UI section.',
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
    betaUiSwitchEnabled,
    switchValue,
    dismissValue,
    toggleBetaUiSwitch,
    dismissBetaUiSwitch,
    toggleDismissBetaUiSwitch,
  }
}
