// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { useApplicationStore } from '#shared/stores/application.ts'

import type { PersonalSettingPlugin } from './types.ts'

export default <PersonalSettingPlugin>{
  label: __('Password'),
  category: {
    label: __('Security'),
    id: 'category-security',
    order: 9000,
  },
  route: {
    path: 'password',
    name: 'PersonalSettingPassword',
    component: () => import('../../PersonalSettingPassword.vue'),
    level: 2,
    meta: {
      title: __('Password'),
      requiresAuth: true,
      requiredPermission: 'user_preferences.password',
    },
  },
  order: 1000,
  keywords: __(
    'current,new,confirm,change,current password,new password,confirm password,change password',
  ),
  show: () => {
    const { config } = useApplicationStore()

    if (!config.user_show_password_login) return false
    return true
  },
}
