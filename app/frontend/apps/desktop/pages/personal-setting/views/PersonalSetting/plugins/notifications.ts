// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import type { PersonalSettingPlugin } from './types.ts'

export default <PersonalSettingPlugin>{
  label: __('Notifications'),
  category: {
    label: __('Tickets'),
    id: 'category-tickets',
    order: 3000,
  },
  route: {
    path: 'notifications',
    alias: '/profile/notifications',
    name: 'PersonalSettingNotifications',
    component: () => import('../../PersonalSettingNotifications.vue'),
    level: 1,
    meta: {
      title: __('Notifications'),
      requiresAuth: true,
      requiredPermission: 'user_preferences.notifications+ticket.agent',
    },
  },
  order: 1000,
  keywords: __('notifications,tickets'),
}
