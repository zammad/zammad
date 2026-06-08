// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { EnumObjectManagerObjects, EnumSearchableModels } from '#shared/graphql/types.ts'

import UserListTable from '#desktop/components/User/UserListTable.vue'

import User from '../QuickSearch/entities/User.vue'

import type { SearchPlugin } from '../types.ts'

export default <SearchPlugin>{
  name: EnumSearchableModels.User,
  object: EnumObjectManagerObjects.User,
  label: __('User'),
  priority: 200,
  quickSearchResultLabel: __('Found users'),
  quickSearchComponent: User,
  quickSearchResultKey: 'quickSearchUsers',
  permissions: ['ticket.agent', 'admin.user'],
  detailSearchHeaders: ['login', 'firstname', 'lastname', 'organization', 'organization_ids'],
  detailSearchComponent: UserListTable,
}
