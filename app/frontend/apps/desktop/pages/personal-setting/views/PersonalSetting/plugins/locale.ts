// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { PersonalSettingPlugin } from '../../../components/PersonalSettingSidebar/types.ts'

export default <PersonalSettingPlugin>{
  label: __('Language'),
  category: {
    label: __('Profile'),
    id: 'category-profile',
    order: 1000,
  },
  route: {
    path: 'locale',
    name: 'PersonalSettingLocale',
    component: () => import('../../PersonalSettingLocale.vue'),
    level: 2,
    meta: {
      title: __('Language'),
      requiresAuth: true,
      requiredPermission: 'user_preferences.language',
    },
  },
  order: 2000,
  keywords: __('translation,locale,localization'),
}
