// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { AvatarMenuPlugin } from './index.ts'

export default <AvatarMenuPlugin>{
  key: 'sign-out',
  label: __('Sign out'),
  link: '/logout',
  icon: 'box-arrow-in-right',
  separatorTop: true,
  order: 600,
}
