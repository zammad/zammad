// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { EnumObjectManagerObjects } from '#shared/graphql/types.ts'

import { useFlyout } from '../CommonFlyout/useFlyout.ts'

import type { HistoryDescription } from './types'

export const useHistoryFlyout = (name: string, type: EnumObjectManagerObjects) => {
  const flyout = useFlyout({
    name,
    component: () => import('./CommonHistoryFlyout.vue'),
  })

  const openHistoryFlyout = async (props: HistoryDescription) =>
    flyout.open({
      name,
      type,
      ...props,
    })

  return { openHistoryFlyout }
}
