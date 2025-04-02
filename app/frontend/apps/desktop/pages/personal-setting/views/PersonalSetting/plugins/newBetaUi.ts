// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { useCheckNewBetaUi } from '#desktop/pages/personal-setting/composables/permission/useCheckNewBetaUi.ts'

import type { PersonalSettingPlugin } from './types.ts'

export default <PersonalSettingPlugin>{
  label: __('New BETA UI'),
  category: {
    label: __('Profile'),
    id: 'category-profile',
    order: 1000,
  },
  route: {
    path: 'new-beta-ui',
    alias: '/profile/newbetaui',
    name: 'PersonalSettingNewBetaUi',
    component: () => import('../../PersonalSettingNewBetaUi.vue'),
    level: 2,
    meta: {
      title: __('New BETA UI'),
      requiresAuth: true,
      requiredPermission: 'user_preferences.beta_ui_switch',
    },
  },
  order: 1500,
  keywords: __('new,beta,desktop view,desktop ui'),
  show: () => {
    const { newBetaUiEnabled } = useCheckNewBetaUi()

    return newBetaUiEnabled.value
  },
}
