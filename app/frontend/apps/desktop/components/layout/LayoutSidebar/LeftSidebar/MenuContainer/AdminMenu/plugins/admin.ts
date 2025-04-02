// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import type { AdminMenuItem } from '#desktop/components/layout/LayoutSidebar/LeftSidebar/types.ts'
import { useNewBetaUi } from '#desktop/composables/useNewBetaUi.ts'

export default {
  order: 100,
  key: 'admin',
  label: __('Administration'),
  permission: ['admin.*'],
  variant: 'neutral',
  icon: 'gear',
  onClick: () => {
    const { switchValue, toggleBetaUiSwitch } = useNewBetaUi()

    if (!switchValue.value) {
      window.location.href = '/#manage' // this is a transition solution, the actual link will be different
      return
    }

    // Make sure to clear the beta switch flag, so the admin does not end up in redirect loop.
    toggleBetaUiSwitch('/#manage')
  },
} as AdminMenuItem
