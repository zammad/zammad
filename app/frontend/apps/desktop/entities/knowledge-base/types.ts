// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { Scalars } from '#shared/graphql/schema-types.ts'

// Derived from the schema scalar, so the icon sprite file names cannot drift
//   from what the backend allows.
export type KnowledgeBaseIconSet = Scalars['KnowledgeBaseIconSet']['output']

export interface DeletableKnowledgeBaseCategory {
  id: string
  title?: Maybe<string>
  isDeletable?: Maybe<boolean>
}
