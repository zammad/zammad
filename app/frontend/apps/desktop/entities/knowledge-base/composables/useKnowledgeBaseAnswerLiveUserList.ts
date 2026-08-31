// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { toValue } from 'vue'

import { useTaskbarLiveUserList } from '#shared/entities/taskbar/composables/useTaskbarLiveUserList.ts'
import { EnumTaskbarApp } from '#shared/graphql/types.ts'
import { SubscriptionHandler } from '#shared/server/apollo/handler/index.ts'

import { useKnowledgeBaseAnswerLiveUserUpdatesSubscription } from '#desktop/entities/knowledge-base/graphql/subscriptions/knowledgeBaseAnswerLiveUserUpdates.api.ts'

import type { MaybeRefOrGetter } from 'vue'

// The other editors of the answer translation this tab holds.
//
// `taskbarKey` is the tab's own key ('KnowledgeBase__Answer-42-de-de'), taken from
//   useTaskbarTab rather than rebuilt: it carries the locale, so an answer edited in two
//   languages has two lists, and it has to match what the backend collected the entries under.
export const useKnowledgeBaseAnswerLiveUserList = (
  taskbarKey: MaybeRefOrGetter<string | undefined>,
) => {
  const liveUserSubscription = new SubscriptionHandler(
    useKnowledgeBaseAnswerLiveUserUpdatesSubscription(
      () => ({
        key: toValue(taskbarKey) as string,
        app: EnumTaskbarApp.Desktop,
      }),
      () => ({
        // Same reason as the ticket list: an answer opened a second time is already in the
        // subscription cache, and reading it back through the proxy throws. Nothing needs the
        // cache here - the list only ever comes from the server.
        fetchPolicy: 'no-cache',
        enabled: Boolean(toValue(taskbarKey)),
      }),
    ),
  )

  return useTaskbarLiveUserList(
    liveUserSubscription,
    (data) => data.knowledgeBaseAnswerLiveUserUpdates.liveUsers || [],
  )
}
