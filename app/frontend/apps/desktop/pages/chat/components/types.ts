// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

// The fixed fields, next to the ones every topic adds under its own name.
export type ChatSettingsFormData = {
  maxWindows: number | string
  alternativeName?: string
  avatarEnabled?: boolean
} & Record<string, unknown>

// What a window shows over its thread: one part of the details at a time.
export type ChatWindowDetail = 'transfer' | 'tags' | 'meta'

// A note in the footer of a window or at the end of its thread, where it has the time it ended.
export type ChatFooterNote = { text: string; time?: string }
