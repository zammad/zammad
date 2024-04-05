// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { AvatarMenuPlugin } from './index.ts'

export default <AvatarMenuPlugin>{
  key: 'personal-setting',
  label: __('Profile settings'),
  link: '/personal-setting',
  icon: 'person-gear',
  order: 400,
}
