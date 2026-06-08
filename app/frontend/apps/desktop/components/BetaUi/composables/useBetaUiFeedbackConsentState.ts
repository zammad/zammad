// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { useLocalStorage } from '@vueuse/core'
import { createGlobalState } from '@vueuse/core'

export const useBetaUiFeedbackConsentState = createGlobalState(() => {
  // In test environment the initial value should be 'true', to not have to close the dialog on every test run.
  //   Otherwise, we initialize the flag as 'null' to indicate that no consent has been given yet.
  const hasFeedbackConsent = useLocalStorage<'true' | 'false' | 'null'>(
    'beta-ui-feedback-consent',
    VITE_TEST_MODE ? 'true' : 'null',
  )

  return { hasFeedbackConsent }
})
