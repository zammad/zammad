// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { useApplicationConfigTwoFactor } from '#shared/composables/authentication/useApplicationConfigTwoFactor.ts'

import type { PersonalSettingPlugin } from './types.ts'

export default <PersonalSettingPlugin>{
  label: __('Two-factor Authentication'),
  category: {
    label: __('Security'),
    id: 'category-security',
    order: 2000,
  },
  route: {
    path: 'two-factor-auth',
    name: 'PersonalSettingTwoFactorAuth',
    component: () => import('../../PersonalSettingTwoFactorAuth.vue'),
    level: 2,
    meta: {
      title: __('Two-factor Authentication'),
      requiresAuth: true,
      requiredPermission: 'user_preferences.two_factor_authentication',
    },
  },
  order: 2000,
  keywords: __('twofactor,2fa,security key,passkey,authenticator app'),
  show: () => {
    const { hasEnabledMethods } = useApplicationConfigTwoFactor()
    return hasEnabledMethods.value
  },
}
