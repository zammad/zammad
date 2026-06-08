// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { EnumObjectManagerObjects } from '#shared/graphql/types.ts'

import { openFlyout } from '#desktop/components/CommonFlyout/useFlyout.ts'
import { useHistoryFlyout } from '#desktop/components/CommonHistoryFlyout/useHistoryFlyout.ts'

import { useUserHistoryQuery } from '../graphql/queries/history.api.ts'

export const USER_HISTORY_FLYOUT_NAME = 'user-history-flyout'

export const openUserHistoryFlyout = (userId: string) => {
  openFlyout(USER_HISTORY_FLYOUT_NAME, {
    name: USER_HISTORY_FLYOUT_NAME,
    type: EnumObjectManagerObjects.User,
    query: () => useUserHistoryQuery({ userId }),
  })
}

export const useUserHistory = () => {
  useHistoryFlyout(USER_HISTORY_FLYOUT_NAME, EnumObjectManagerObjects.User)

  return { openUserHistoryFlyout }
}
