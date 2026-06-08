// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { computed, toRef, watch } from 'vue'
import { useRoute } from 'vue-router'

import { useAuthenticationStore } from '#shared/stores/authentication.ts'

import { closeDialog, openDialog, useDialog } from '#desktop/components/CommonDialog/useDialog.ts'

import { useBetaUiFeedbackConsentState } from './useBetaUiFeedbackConsentState.ts'

export const DIALOG_NAME = 'beta-ui-feedback-consent'

export const showFeedbackConsent = () => openDialog(DIALOG_NAME, {}, true)

export const handleFeedbackConsent = (consent: boolean) => {
  const { hasFeedbackConsent } = useBetaUiFeedbackConsentState()

  // The feedback consent is considered given when the dialog is closed without canceling.
  hasFeedbackConsent.value = consent.toString() as 'true' | 'false'

  closeDialog(DIALOG_NAME, true)
}

export const useBetaUiFeedbackConsent = () => {
  const { hasFeedbackConsent } = useBetaUiFeedbackConsentState()

  const route = useRoute()

  const authenticated = toRef(useAuthenticationStore(), 'authenticated')

  const afterAuthRouteActive = computed(
    // route.name is undefined when you visit or reload the after auth phase e.g two-factor auth
    () => route.name === 'LoginAfterAuth' || route.name === 'Login' || route.name === undefined,
  )

  watch([afterAuthRouteActive, authenticated], ([afterAuth, isAuthenticated]) => {
    if (hasFeedbackConsent.value !== 'null' || afterAuth || !isAuthenticated) return

    showFeedbackConsent()
  })

  return { showFeedbackConsent, handleFeedbackConsent, hasFeedbackConsent }
}

// This should only be called once from AppDesktop.vue
export const initializeBetaUiFeedbackConsentDialog = () =>
  useDialog({
    name: DIALOG_NAME,
    global: true,
    component: () => import('../BetaUiFeedbackConsentDialog.vue'),
  })
