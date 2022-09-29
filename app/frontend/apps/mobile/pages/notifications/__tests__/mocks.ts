// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { NotificationListItem } from '../types/notificaitons'

export const getMockedNotification = (
  item: Partial<NotificationListItem> = {},
): NotificationListItem => {
  return {
    id: '154362',
    title: 'State changed to closed',
    user: { id: '2', lastname: 'Biden', firstname: 'Joe' },
    read: false,
    createdAt: new Date().toUTCString(),
    ...item,
  }
}
