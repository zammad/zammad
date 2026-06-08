// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { User } from '#shared/graphql/types.ts'

import {
  openUserHistoryFlyout,
  useUserHistory,
} from '#desktop/entities/user/composables/useUserHistory.ts'
import type { DetailViewActionPlugin } from '#desktop/types/actions.ts'

export default <DetailViewActionPlugin>{
  key: 'history-user',
  label: __('History'),
  icon: 'clock-history',
  order: 300,
  permission: ['ticket.agent', 'admin.user'],
  initialize: useUserHistory,
  onClick: (user: User) => openUserHistoryFlyout(user.id),
}
