// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { StoreObject } from '@apollo/client'

// As the cache identifies it: by its type name and id.
export type TagAssignmentEntity = StoreObject & { id: string }

export interface TagAssignmentOptions {
  entity: () => TagAssignmentEntity | undefined
  tags: () => string[]
}

export interface TagEdit {
  objectId: string
  cacheId: string
  tag: string
  add: boolean
  // The authentication it was made in. Once that is gone, it is neither sent nor undone anymore,
  //   also not once the next agent is logged in.
  generation: number
}

// What the server holds for one tag of one record while edits of it are on their way.
export interface TagState {
  stored: boolean
  // Where the tag stood, to put it back there.
  index: number
  pending: number
}
