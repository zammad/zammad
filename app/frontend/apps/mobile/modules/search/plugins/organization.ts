// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import OrganizationItem from '@mobile/components/Organization/OrganizationItem.vue'
import type { OrganizationItemData } from '@mobile/components/Organization/types'
import { type SearchPlugin } from './index'

export default <SearchPlugin<OrganizationItemData>>{
  headerTitle: __('Organizations'),
  component: OrganizationItem,
  link: '/organizations/#{id}',
  permissions: ['*'], // TODO 2022-06-01 Sheremet V.A.
  order: 300,
  itemTitle: (organization) => organization.name,
}
