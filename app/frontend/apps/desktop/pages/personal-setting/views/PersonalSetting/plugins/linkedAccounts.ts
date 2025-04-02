// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { useThirdPartyAuthentication } from '#shared/composables/authentication/useThirdPartyAuthentication.ts'

import type { PersonalSettingPlugin } from './types.ts'

export default <PersonalSettingPlugin>{
  label: __('Linked Accounts'),
  category: {
    label: __('Security'),
    id: 'category-security',
    order: 2000,
  },
  route: {
    path: 'linked-accounts',
    alias: '/profile/linked',
    name: 'PersonalSettingLinkedAccounts',
    component: () => import('../../PersonalSettingLinkedAccounts.vue'),
    level: 2,
    meta: {
      title: __('Linked Accounts'),
      requiresAuth: true,
      requiredPermission: 'user_preferences.linked_accounts',
    },
  },
  order: 5000,
  keywords: __(
    'linked accounts,facebook,github,gitlab,google,linkedin,microsoft,saml',
  ),
  show: () => {
    const { hasEnabledProviders } = useThirdPartyAuthentication()
    return hasEnabledProviders.value
  },
}
