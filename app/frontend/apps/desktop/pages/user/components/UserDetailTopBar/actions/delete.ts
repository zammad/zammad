// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { User } from '#shared/graphql/types.ts'

import { initializeBetaUi } from '#desktop/components/BetaUi/composables/useBetaUi.ts'
import type { DetailViewActionPlugin } from '#desktop/types/actions.ts'

export default <DetailViewActionPlugin>{
  key: 'delete-user',
  label: __('Delete'),
  icon: 'trash',
  order: 400,
  permission: ['admin.data_privacy', 'admin.user'],
  onClick: (user?: User) => {
    if (!user) return

    const { switchValue, clearSwitchAndRedirect } = initializeBetaUi()

    const url = `/#system/data_privacy/${user.internalId}`

    if (!switchValue.value) {
      window.location.href = url
      return
    }

    // Make sure to clear the beta switch flag, so the admin does not end up in redirect loop.
    clearSwitchAndRedirect(url)
  },
}
