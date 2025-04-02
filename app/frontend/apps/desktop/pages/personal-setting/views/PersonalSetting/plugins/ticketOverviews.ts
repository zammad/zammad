// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import type { PersonalSettingPlugin } from './types.ts'

export default <PersonalSettingPlugin>{
  label: __('Overviews'),
  category: {
    label: __('Tickets'),
    id: 'category-tickets',
    order: 3000,
  },
  route: {
    path: 'ticket-overviews',
    alias: '/profile/overviews',
    name: 'PersonalSettingOverviews',
    component: () => import('../../PersonalSettingOverviews.vue'),
    level: 2,
    meta: {
      title: __('Overviews'),
      requiresAuth: true,
      requiredPermission: 'user_preferences.overview_sorting',
    },
  },
  order: 2000,
  keywords: __('order,sort,overview,ticket,sorting'),
}
