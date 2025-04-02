// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { computed } from 'vue'

import { useApplicationStore } from '#shared/stores/application.ts'

export const useCheckNewBetaUi = () => {
  const { config } = useApplicationStore()

  const newBetaUiEnabled = computed(() => !!config.ui_desktop_beta_switch)

  return {
    newBetaUiEnabled,
  }
}
