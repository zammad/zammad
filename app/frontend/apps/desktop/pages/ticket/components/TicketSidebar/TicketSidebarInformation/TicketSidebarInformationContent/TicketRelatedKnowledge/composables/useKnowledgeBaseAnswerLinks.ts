// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { useObjectLinkMutations } from '#desktop/entities/link/composables/useObjectLinkMutations.ts'

// Linking answers to the open ticket. The AI suggestions need no cache update of their own: they
//   are rendered without the answers the link list already holds.
export const useKnowledgeBaseAnswerLinks = (ticketId: ID, targetType: string) => {
  const { addLink, removeLink } = useObjectLinkMutations(ticketId, targetType)

  return {
    linkAnswer: (answerId: string) => addLink(answerId),
    unlinkAnswer: (answerId: string) => removeLink(answerId),
  }
}
