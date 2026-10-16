// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { computed, ref } from 'vue'

import type { TicketArticle, TicketById } from '#shared/entities/ticket/types.ts'
import type {
  TicketArticleAction,
  TicketArticlePerformOptions,
} from '#shared/entities/ticket-article/action/plugins/types.ts'
import type { PendingArticleAction } from '#shared/entities/ticket-article/composables/usePendingArticleAction/types.ts'
import log from '#shared/utils/log.ts'

// Actions with a server round-trip (e.g. quoting an email) resolve their
//   perform promise only once the reply form is open. The triggering control
//   carries the wait until then.
export const usePendingArticleAction = () => {
  const pendingAction = ref<PendingArticleAction>()

  const isPending = computed(() => !!pendingAction.value)

  const isActionPending = (name: string, articleId: string) =>
    pendingAction.value?.name === name && pendingAction.value?.articleId === articleId

  const isArticlePending = (articleId: string) => pendingAction.value?.articleId === articleId

  const performAction = async (
    action: TicketArticleAction,
    ticket: TicketById,
    article: TicketArticle,
    options: TicketArticlePerformOptions,
  ) => {
    if (!action.perform || pendingAction.value) return

    pendingAction.value = { name: action.name, articleId: article.id }

    // The plugins notify the user about server errors themselves; anything
    //   else is logged, as the click handlers do not await the action.
    try {
      await action.perform(ticket, article, options)
    } catch (error) {
      log.error(`[Article Action] "${action.name}" failed`, error)
    } finally {
      pendingAction.value = undefined
    }
  }

  return { isPending, isActionPending, isArticlePending, performAction }
}
