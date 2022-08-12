// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import UserItem from '@mobile/components/User/UserItem.vue'
import type { SearchPlugin } from './index'

export default <SearchPlugin>{
  model: 'User',
  headerLabel: __('Users'),
  component: UserItem,
  order: 200,
  link: '/users/#{internalId}',
  permissions: ['ticket.agent'],
  icon: { name: 'user', size: 'base' },
  iconBg: 'bg-pink',
}
