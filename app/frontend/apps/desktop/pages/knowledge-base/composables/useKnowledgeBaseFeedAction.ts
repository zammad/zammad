// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { storeToRefs } from 'pinia'
import { computed, type Ref } from 'vue'

import { useFlyout } from '#desktop/components/CommonFlyout/useFlyout.ts'
import type { MenuItem } from '#desktop/components/CommonPopoverMenu/types.ts'
import { useKnowledgeBaseAccess } from '#desktop/entities/knowledge-base/composables/useKnowledgeBaseAccess.ts'
import { useKnowledgeBaseStore } from '#desktop/entities/knowledge-base/stores/knowledgeBase.ts'

export const KNOWLEDGE_BASE_FEED_FLYOUT_NAME = 'knowledge-base-feed'

// The header entry opening the feed flyout, shared by the browse and the answer
//   header. `categoryId` is the browsed category (an answer's own category on the
//   answer page), which the flyout offers a second feed for.
export const useKnowledgeBaseFeedAction = (categoryId: Ref<string | undefined>) => {
  const { canRead } = useKnowledgeBaseAccess()
  const { knowledgeBase } = storeToRefs(useKnowledgeBaseStore())

  const { open: openFeedFlyout } = useFlyout({
    name: KNOWLEDGE_BASE_FEED_FLYOUT_NAME,
    component: () =>
      import('#desktop/pages/knowledge-base/components/KnowledgeBaseFeedFlyout/KnowledgeBaseFeedFlyout.vue'),
  })

  // The feeds carry internal content, so they are for readers and editors only,
  //   and — like in the old interface — follow the knowledge base's feed setting.
  const feedActions = computed<MenuItem[]>(() => {
    if (!canRead.value || !knowledgeBase.value?.showFeedIcon) return []

    return [
      {
        key: 'knowledge-base-feed',
        label: __('Set up RSS feed'),
        icon: 'rss',
        onClick: () => openFeedFlyout({ categoryId: categoryId.value }),
      },
    ]
  })

  return { feedActions }
}
