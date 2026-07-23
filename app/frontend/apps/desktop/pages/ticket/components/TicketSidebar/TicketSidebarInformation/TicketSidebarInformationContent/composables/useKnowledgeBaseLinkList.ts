// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { computed, type Ref } from 'vue'

import type { KnowledgeBaseAnswerTranslationFragment } from '#shared/graphql/types.ts'

import { useObjectLinks } from '#desktop/pages/ticket/composables/useObjectLinks.ts'

export const useKnowledgeBaseLinkList = (
  ticketId: Ref<string>,
  { enabled }: { enabled: Ref<boolean> },
) => {
  // The link target class the ticket's knowledge base answer links are stored under.
  const TARGET_TYPE = 'KnowledgeBase::Answer::Translation'

  const object = computed(() => ({ id: ticketId.value }))
  const { links, linkListIsLoading: isLoading } = useObjectLinks(object, TARGET_TYPE, { enabled })

  const linkedAnswers = computed(
    () => links.value.map((link) => link.item) as KnowledgeBaseAnswerTranslationFragment[],
  )

  const linkedAnswerIds = computed(() => links.value.map((link) => link.item.id))

  return { linkedAnswers, linkedAnswerIds, targetType: TARGET_TYPE, isLoading }
}
