// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { User } from '#shared/graphql/types.ts'

import { openUserEditFlyout, useUserEdit } from '#desktop/entities/user/composables/useUserEdit.ts'
import type { DetailViewActionPlugin } from '#desktop/types/actions.ts'

export default <DetailViewActionPlugin>{
  key: 'edit-user',
  label: __('Edit'),
  icon: 'pencil',
  order: 100,
  permission: ['ticket.agent', 'admin.user'],
  show: (user?: User) => user?.policy.update,
  initialize: useUserEdit,
  onClick: (user?: User) => {
    if (!user) return
    openUserEditFlyout(user)
  },
}
