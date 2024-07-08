// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import AvatarMenuAppearanceItem from '../AvatarMenuAppearanceItem.vue'

import type { AvatarMenuPlugin } from './index.ts'

export default <AvatarMenuPlugin>{
  key: 'appearance',
  label: __('Appearance'),
  icon: 'brightness-alt-high',
  noCloseOnClick: true,
  order: 100,
  component: AvatarMenuAppearanceItem,
  permission: 'user_preferences.appearance',
}
