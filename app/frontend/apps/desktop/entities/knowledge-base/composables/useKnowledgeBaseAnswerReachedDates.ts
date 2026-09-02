// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { computed, toValue } from 'vue'

import { useReactiveNow } from '#shared/composables/useReactiveNow.ts'
import { EnumKnowledgeBaseVisibility } from '#shared/graphql/types.ts'

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

  // The state the answer is actually in right now: the last state of the machine
  //   (internalAt < publishedAt < archivedAt) whose date has been reached.
  const reachedDate = computed(() => {
    const { internalAt, publishedAt, archivedAt } = reachedDates.value

    return archivedAt ?? publishedAt ?? internalAt
  })

  // The same rung named as a state, which is what the server's `visibility` field says - and only
  //   says as of the request that answered it: it is derived once, on the server's clock, so a
  //   schedule falling due while the page is open leaves it naming a state the answer has left.
  //   Read off the same reached dates here, it moves with `reachedDate` instead, and a badge can no
  //   longer disagree with the date it is stamped with.
  //
  // Mirrors CanBePublished::StateMachine#calculated_state, save for its `draft`: a caller that has
  //   no dates at all is not necessarily looking at a draft - the create header has nothing but the
  //   visibility being picked in the form - so what "none reached" means is left to the caller.
  const reachedVisibility = computed(() => {
    const { internalAt, publishedAt, archivedAt } = reachedDates.value

    if (archivedAt) return EnumKnowledgeBaseVisibility.Archived
    if (publishedAt) return EnumKnowledgeBaseVisibility.Published
    if (internalAt) return EnumKnowledgeBaseVisibility.Internal

    return undefined
  })

  return { reachedDates, reachedDate, reachedVisibility }
}
