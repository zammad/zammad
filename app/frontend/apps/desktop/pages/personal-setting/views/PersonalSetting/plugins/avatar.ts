// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import type { PersonalSettingPlugin } from './types.ts'

export default <PersonalSettingPlugin>{
  label: __('Avatar'),
  category: {
    label: __('Profile'),
    id: 'category-profile',
    order: 1000,
  },
  route: {
    path: 'avatar',
    alias: '/profile/avatar',
    name: 'PersonalSettingAvatar',
    component: () => import('../../PersonalSettingAvatar.vue'),
    level: 2,
    meta: {
      title: __('Avatar'),
      requiresAuth: true,
      requiredPermission: 'user_preferences.avatar',
    },
  },
  order: 3000,
  keywords: __('camera,image,photo,picture'),
}
