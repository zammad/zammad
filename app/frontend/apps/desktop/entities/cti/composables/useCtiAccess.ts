// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { computed } from 'vue'

import { useApplicationStore } from '#shared/stores/application.ts'

export const useCtiAccess = () => {
  const application = useApplicationStore()

  const isIntegrationEnabled = computed(() =>
    Boolean(
      application.config.cti_integration ||
      application.config.sipgate_integration ||
      application.config.placetel_integration,
    ),
  )

  return { isIntegrationEnabled }
}
