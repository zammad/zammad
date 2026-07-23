// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { TicketAiRelatedKnowledgeBaseAnswersQuery } from '#shared/graphql/types.ts'

export type RelatedAnswer = NonNullable<
  NonNullable<
    TicketAiRelatedKnowledgeBaseAnswersQuery['ticketAIRelatedKnowledgeBaseAnswers']['answers']
  >[number]
>
