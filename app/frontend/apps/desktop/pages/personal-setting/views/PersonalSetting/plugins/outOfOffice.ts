// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import type { PersonalSettingPlugin } from './types.ts'

export default <PersonalSettingPlugin>{
  label: __('Out of Office'),
  category: {
    label: __('Profile'),
    id: 'category-profile',
    order: 1000,
  },
  route: {
    path: 'out-of-office',
    alias: '/profile/out_of_office',
    name: 'PersonalSettingOutOfOffice',
    component: () => import('../../PersonalSettingOutOfOffice.vue'),
    level: 2,
    meta: {
      title: __('Out of Office'),
      requiresAuth: true,
      requiredPermission: 'user_preferences.out_of_office+ticket.agent',
    },
  },
  order: 4000,
  keywords: __('vacation,holiday,replacement,time off'),
}
