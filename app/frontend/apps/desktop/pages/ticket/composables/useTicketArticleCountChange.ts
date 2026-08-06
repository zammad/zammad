// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { toValue, watch, type MaybeRefOrGetter } from 'vue'

/**
 * Calls back when the ticket gains or loses an article, for features that have to redo work when the
 * conversation moved on (AI summary, related knowledge base answers).
 *
 * Callers hand in the `articleCount` of the ticket they already hold, rather than every feature
 * subscribing to the article updates on its own: the ticket detail view holds that subscription
 * anyway, and the count leaves out the System articles a consumer would otherwise have to filter
 * itself.
 */
export const useTicketArticleCountChange = (
  articleCount: MaybeRefOrGetter<Maybe<number> | undefined>,
  onChange: () => void,
) => {
  watch(
    () => toValue(articleCount),
    (count, previousCount) => {
      // Nothing to compare against yet: the first reading is the state the consumer already covers.
      if (count === undefined || count === null) return
      if (previousCount === undefined || previousCount === null) return

      onChange()
    },
  )
}
