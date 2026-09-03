// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { onScopeDispose } from 'vue'

import { useKeepAliveHooks } from '#desktop/composables/useKeepAliveHooks.ts'

import { useKnowledgeBaseStore } from '../stores/knowledgeBase.ts'

// The content update ping, for a view that outlives being looked at.
//
// A section page is kept alive (`useSectionPageCache`), so an off-screen view still holds its
//   queries and would refetch for a page nobody is on - the same for a tab in the taskbar. The ping
//   is handed over only while the view is on screen, and the backlog settles as one refetch.
//
// That catch-up passes an empty list, which every consumer reads as "refetch anything": the skipped
//   pings cannot be replayed. It runs on every return, not only after a missed ping, because the
//   store gates the subscription on the route's locale - a change made while the knowledge base was
//   left reaches nobody at all.
export const useKnowledgeBaseContentUpdates = (
  onUpdate: (affectedCategoryIds: string[]) => void,
) => {
  const { contentUpdates } = useKnowledgeBaseStore()

  let onScreen = true

  const { off } = contentUpdates.onResult(({ data }) => {
    if (!onScreen) return

    onUpdate(data?.knowledgeBaseContentUpdates?.affectedCategoryIds ?? [])
  })

  useKeepAliveHooks({
    onDeactivated: () => {
      onScreen = false
    },
    // `onReactivated`, not `onActivated`: the first activation is the view being mounted, which has
    //   nothing to catch up on.
    onReactivated: () => {
      onScreen = true

      onUpdate([])
    },
  })

  onScopeDispose(off)
}
