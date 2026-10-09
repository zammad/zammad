// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { ShownPushNotification } from '#shared/sw/pushNotificationDatabase.ts'

// jsdom has no IndexedDB, this keeps the entries in memory instead.
const entries = new Map<string, ShownPushNotification>()

export const resetPushNotificationDatabase = () => entries.clear()

export const pushNotificationDatabaseMock = {
  isDatabaseAvailable: () => true,
  readEntries: async () => [...entries.values()],
  putEntry: async (entry: ShownPushNotification) => {
    entries.set(entry.tag, entry)
  },
  deleteEntries: async (tags: string[]) => {
    tags.forEach((tag) => entries.delete(tag))
  },
  deleteDatabase: async () => {
    entries.clear()
  },
}
