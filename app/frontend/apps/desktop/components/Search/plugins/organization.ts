// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { EnumSearchableModels } from '#shared/graphql/types.ts'

import OrganizationListTable from '#desktop/components/Organization/OrganizationListTable.vue'

import Organization from '../QuickSearch/entities/Organization.vue'

import type { SearchPlugin } from '../types.ts'

export default <SearchPlugin>{
  name: EnumSearchableModels.Organization,
  label: __('Organization'),
  priority: 300,
  quickSearchResultLabel: __('Found organizations'),
  quickSearchComponent: Organization,
  quickSearchResultKey: 'quickSearchOrganizations',
  permissions: ['ticket.agent', 'admin.organization'],
  detailSearchHeaders: ['name', 'shared'],
  detailSearchComponent: OrganizationListTable,
}
