// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { Organization } from '#shared/graphql/types.ts'

import {
  openUserCreateFlyout,
  useUserCreate,
} from '#desktop/entities/user/composables/useUserCreate.ts'
import type { DetailViewActionPlugin } from '#desktop/types/actions.ts'

export default <DetailViewActionPlugin>{
  key: 'new-user',
  label: __('New user'),
  icon: 'plus-square-fill',
  variant: 'secondary',
  showLabel: true,
  permission: ['ticket.agent', 'admin.user'],
  order: 200,
  topLevel: true,
  initialize: useUserCreate,
  onClick: (organization?: Organization) => {
    if (!organization) return

    openUserCreateFlyout({
      title: __('New user'),
      organization,
    })
  },
}
