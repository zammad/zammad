// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type {
  MentionKnowledgeBaseItem,
  MentionKnowledgeBaseRelatedItem,
  MentionTextItem,
  MentionUserItem,
} from '#shared/components/Form/fields/FieldEditor/types.ts'

export type PossibleItem =
  | MentionUserItem
  | MentionKnowledgeBaseItem
  | MentionKnowledgeBaseRelatedItem
  | MentionTextItem
