// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { KnowledgeBaseAnswerTranslationFragment } from '#shared/graphql/types.ts'

import type { RelatedAnswer } from './types.ts'

// An already-linked answer is no suggestion. The server drops them from the search result, but that
//   result arrives asynchronously, so keep the two lists disjoint here as well. Matched on the
//   answer rather than the translation, mirroring the server: linking one locale covers all of them.
export const excludeLinkedAnswers = (
  suggestedAnswers: RelatedAnswer[],
  linkedAnswers: KnowledgeBaseAnswerTranslationFragment[],
) => {
  const linkedAnswerIds = new Set(linkedAnswers.map((translation) => translation.answer.id))

  return suggestedAnswers.filter((answer) => !linkedAnswerIds.has(answer.translation.answer.id))
}
