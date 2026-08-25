// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { EnumKnowledgeBaseVisibility, Scalars } from '#shared/graphql/schema-types.ts'

// Derived from the schema scalar, so the icon sprite file names cannot drift
//   from what the backend allows.
export type KnowledgeBaseIconSet = Scalars['KnowledgeBaseIconSet']['output']

export interface DeletableKnowledgeBaseCategory {
  id: string
  title?: Maybe<string>
  isDeletable?: Maybe<boolean>
}

// What the answer create form submits. `scheduledAt` answers "now or later" all by itself: the
//   option that publishes right away holds no timestamp at all.
export interface KnowledgeBaseAnswerCreateFormData {
  categoryId: string | number
  title: string
  body?: string
  tags?: string[]
  visibility?: EnumKnowledgeBaseVisibility
  scheduledAt?: string | null
  // The locale the draft is written in, from the route rather than the form.
  locale: string
}
