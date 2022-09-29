// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { AvatarUser } from '@shared/components/CommonUserAvatar'

export interface NotificationListItem {
  id: string
  read: boolean
  user: AvatarUser
  title: string
  message?: string
  createdAt: string
}
