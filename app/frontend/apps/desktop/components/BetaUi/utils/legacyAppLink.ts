// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { initializeBetaUi } from '#desktop/components/BetaUi/composables/useBetaUi.ts'

// Links which point into the legacy app (e.g. the knowledge base answer view) cannot be
//   followed while the BETA UI switch is active: the legacy app redirects straight back
//   to the new app on boot, so the user never reaches the target page. Clearing the
//   switch flag beforehand keeps the browser navigation itself untouched, which also
//   covers links opening in a new tab.
//   :TODO Remove once the target views are available in the new app.
export const prepareLegacyAppLinkNavigation = () => {
  const { switchValue } = initializeBetaUi()

  if (!switchValue.value) return

  switchValue.value = null
}
