// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { ref, type Ref } from 'vue'
import { useRoute } from 'vue-router'

import { getCSRFToken } from '#shared/server/apollo/utils/csrfToken.ts'
import { useApplicationStore } from '#shared/stores/application.ts'
import type { ThirdPartyAuthProvider } from '#shared/types/authentication.ts'

// Keys are shared with the legacy desktop app (app/assets/javascripts/app/lib/app_post/third_party_login_auto_redirect.coffee).
const PAUSED_KEY = 'third-party-login-auto-redirect-paused'
const LAST_REDIRECT_KEY = 'third-party-login-auto-redirect-at'

// A callback which returns to the login page without a session (e.g. maintenance mode) must not loop.
const LOOP_GUARD_MS = 60_000

// Shared by all tabs, otherwise another open tab would sign the user in again.
export const pauseThirdPartyLoginAutoRedirect = () => {
  // A full storage must not stop the logout.
  try {
    localStorage.setItem(PAUSED_KEY, 'true')
  } catch {
    // Nothing to do, the next login page redirects again.
  }
}

export const resumeThirdPartyLoginAutoRedirect = () => {
  localStorage.removeItem(PAUSED_KEY)
  sessionStorage.removeItem(LAST_REDIRECT_KEY)
}

const redirectedRecently = () => {
  const lastRedirect = Number(sessionStorage.getItem(LAST_REDIRECT_KEY))

  return lastRedirect > 0 && Date.now() - lastRedirect < LOOP_GUARD_MS
}

const submitProviderForm = (provider: ThirdPartyAuthProvider) => {
  const form = document.createElement('form')
  form.method = 'post'
  form.action = provider.url

  const csrfToken = document.createElement('input')
  csrfToken.type = 'hidden'
  csrfToken.name = 'authenticity_token'
  csrfToken.value = getCSRFToken() ?? ''

  form.appendChild(csrfToken)
  document.body.appendChild(form)
  form.submit()
}

export const useThirdPartyAuthenticationAutoRedirect = (
  enabledProviders: Ref<ThirdPartyAuthProvider[]>,
) => {
  const application = useApplicationStore()
  const route = useRoute()

  const autoRedirectProvider = () => {
    const { config } = application

    if (!config.third_party_login_auto_redirect || config.user_show_password_login) return
    if (application.isMaintenanceModeActive) return
    if (enabledProviders.value.length !== 1) return

    // Admin password login link from the email.
    if (route.query.token) return

    if (localStorage.getItem(PAUSED_KEY) || redirectedRecently()) return

    return enabledProviders.value[0]
  }

  const provider = autoRedirectProvider()
  const isAutoRedirecting = ref(Boolean(provider))

  if (provider) {
    sessionStorage.setItem(LAST_REDIRECT_KEY, String(Date.now()))
    submitProviderForm(provider)
  }

  return { isAutoRedirecting }
}
