// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { StoredFile } from '#shared/graphql/types.ts'

import type { Except } from 'type-fest'

export type Attachment = Except<
  StoredFile,
  '__typename' | 'id' | 'createdAt' | 'updatedAt'
>
