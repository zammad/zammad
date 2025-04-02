// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { useCheckTokenAccess } from '../../../composables/permission/useCheckTokenAccess.ts'

import type { PersonalSettingPlugin } from './types.ts'

export default <PersonalSettingPlugin>{
  label: __('Token Access'),
  category: {
    label: __('Security'),
    id: 'category-security',
    order: 9000,
  },
  route: {
    path: 'token-access',
    alias: '/profile/token_access',
    name: 'PersonalSettingTokenAccess',
    component: () => import('../../PersonalSettingTokenAccess.vue'),
    level: 2,
    meta: {
      title: __('Token Access'),
      requiresAuth: true,
      requiredPermission: 'user_preferences.access_token',
    },
  },
  order: 4000,
  keywords: __('token access,token,api,access token,application'),
  show: () => {
    const { canUseAccessToken } = useCheckTokenAccess()

    return canUseAccessToken.value
  },
}
