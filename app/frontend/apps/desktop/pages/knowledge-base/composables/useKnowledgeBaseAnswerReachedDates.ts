// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { computed, toValue } from 'vue'

import { useReactiveNow } from '#shared/composables/useReactiveNow.ts'

import type { MaybeRefOrGetter } from 'vue'

interface KnowledgeBaseAnswerVisibilityDates {
  internalAt?: Maybe<string>
  publishedAt?: Maybe<string>
  archivedAt?: Maybe<string>
}

// A publication state is not stored, it is derived from the date each state is reached at (see
//   CanBePublished) - so these three columns carry two different things at once: what the answer has
//   already done, and what it is *going to* do. Only a date that has passed is the answer's own
//   history; one still ahead is a scheduled change.
//
// Which is why every read view filters through this: presenting a date that has not been reached as
//   though it had been makes a draft claim to be published. What is still ahead is shown in one
//   place, as its own section, and only to an editor (KnowledgeBaseAnswerScheduledVisibility).
//
// Reactive against `useReactiveNow`, so a date that falls due shows up where it belongs without a
//   reload - the relative labels rendered from it tick on the same clock.
export const useKnowledgeBaseAnswerReachedDates = (
  answer: MaybeRefOrGetter<KnowledgeBaseAnswerVisibilityDates>,
) => {
  const reactiveNow = useReactiveNow()

  const reachedDates = computed(() => {
    const { internalAt, publishedAt, archivedAt } = toValue(answer)

    const reached = (date?: Maybe<string>) =>
      date && new Date(date).getTime() <= reactiveNow.value.getTime() ? date : undefined

    return {
      internalAt: reached(internalAt),
      publishedAt: reached(publishedAt),
      archivedAt: reached(archivedAt),
    }
  })

  return { reachedDates }
}
