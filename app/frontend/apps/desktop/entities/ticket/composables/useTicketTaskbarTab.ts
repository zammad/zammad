// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { EnumTaskbarEntity } from '#shared/graphql/types.ts'

import { useTaskbarTab } from '#desktop/entities/user/current/composables/useTaskbarTab.ts'
import type { TaskbarTabDetailDataLoaderComposable } from '#desktop/entities/user/current/types.ts'

export const useTicketTaskbarTab: TaskbarTabDetailDataLoaderComposable = () => {
  useTaskbarTab(EnumTaskbarEntity.TicketZoom)

  return {}
}
