// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { useCssVar, useIntersectionObserver } from '@vueuse/core'
import { computed, reactive, type MaybeRefOrGetter, type Ref, type ShallowRef } from 'vue'

import { useKeepAliveHooks } from '#desktop/composables/useKeepAliveHooks.ts'
import type { TicketArticleRow } from '#desktop/pages/ticket/composables/useTicketArticlesRows.ts'

// Tracks the article currently at the top of the viewport. When several
// articles are visible at once, the topmost one (document order) wins.
export const useActiveArticle = (
  rows: Ref<TicketArticleRow[]>,
  articleElements: Readonly<ShallowRef<HTMLElement[] | null>>,
  scrollContainer: MaybeRefOrGetter<HTMLElement | null | undefined>,
) => {
  const intersectingKeys = reactive(new Set<string>())

  // Recompute (and therefore re-observe) whenever the rendered rows change, so
  // freshly loaded articles (via "load more", subscription update) are tracked too.
  // It needs to be an new array to pick up the new identity
  const observedArticleElements = computed(() =>
    rows.value.length ? [...(articleElements.value ?? [])] : [],
  )

  // Push the detection line below the sticky top header, so an article that is
  // only visible *behind* the header is never reported as active.
  const topHeaderHeight = useCssVar('--top-header-height', undefined, { observe: true })

  const rootMargin = computed(() => {
    const offset = Number.parseInt(topHeaderHeight.value || '', 10)

    return `-${offset > 0 ? offset : 0}px 0px 0px 0px`
  })

  // A single IntersectionObserver tracks the visibility of every rendered
  // article and feeds the active-article state. Each article element carries
  // its key in the id attribute (#article-<key>). The scroll container is used
  // as the root, so the header offset above lines up with the header's bottom
  // edge.
  const { pause, resume } = useIntersectionObserver(
    observedArticleElements,
    (entries) => {
      entries.forEach((entry) => {
        const key = entry.target.id.replace('article-', '')

        if (entry.isIntersecting) intersectingKeys.add(key)
        else intersectingKeys.delete(key)
      })
    },
    { root: scrollContainer, rootMargin: rootMargin.value, threshold: 0 },
  )

  useKeepAliveHooks({
    onReactivated: resume,
    onDeactivated: pause,
  })

  const activeArticleKey = computed(
    () => rows.value.find((row) => intersectingKeys.has(row.key))?.key,
  )

  return {
    activeArticleKey,
    topHeaderHeight,
  }
}
