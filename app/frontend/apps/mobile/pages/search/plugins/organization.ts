// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import OrganizationItem from '@mobile/components/Organization/OrganizationItem.vue'
import type { SearchPlugin } from './index'

export default <SearchPlugin>{
  model: 'Organization',
  headerLabel: __('Organizations'),
  component: OrganizationItem,
  link: '/organizations/#{internalId}',
  permissions: ['ticket.agent'],
  order: 300,
  icon: { name: 'organization', size: 'small' },
  iconBg: 'bg-orange',
}
