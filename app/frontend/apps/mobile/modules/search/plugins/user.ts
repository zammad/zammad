// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { UserItemData } from '@mobile/components/User/types'
import UserItem from '@mobile/components/User/UserItem.vue'
import { type SearchPlugin } from './index'

export default <SearchPlugin<UserItemData>>{
  headerTitle: __('Users'),
  component: UserItem,
  order: 200,
  link: '/users/#{id}',
  permissions: ['*'], // TODO 2022-06-01 Sheremet V.A.
  itemTitle: (user) =>
    [user.firstname, user.lastname].filter(Boolean).join(' '),
}
