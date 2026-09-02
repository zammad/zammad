// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { computed, toValue } from 'vue'

import { useReactiveNow } from '#shared/composables/useReactiveNow.ts'
import type { EnumKnowledgeBaseSchedulableVisibility } from '#shared/graphql/types.ts'

import type { MaybeRefOrGetter } from 'vue'

interface KnowledgeBaseAnswerVisibilitySchedule {
  visibility: EnumKnowledgeBaseSchedulableVisibility
  scheduledAt: string
}

interface KnowledgeBaseAnswerVisibilitySchedules {
  visibilitySchedules?: Maybe<KnowledgeBaseAnswerVisibilitySchedule[]>
}

// The forward-looking counterpart of useKnowledgeBaseAnswerReachedDates: that one keeps the dates
//   the answer has already reached, this one the next change it is going to make.
//
// Neither sorted nor filtered beyond the clock, because the field arrives that way already:
//   CanBePublished#visibility_schedules returns future-only entries in the order they take effect -
//   the ordering validations behind it only let the timestamps run in rank order - so the first
//   entry still ahead is the next one to fire.
//
// Which leaves the clock a single job, and it is the reason this filters at all rather than handing
//   the field over as it arrives: a page left open past a due date. Reactive against
//   `useReactiveNow` for it, the very clock the reached-date badges tick on - so a schedule falling
//   due stops being a schedule here at the moment it becomes a reached date over there.
//
// Absent rather than empty for anybody who may not edit the answer: the field is denied to them
//   (Gql::Types::KnowledgeBase::AnswerType#visibility_schedules, gated on AnswerPolicy#update?), so
//   its absence is the permission check and no caller needs one of its own.
export const useKnowledgeBaseAnswerNextVisibilitySchedule = (
  answer: MaybeRefOrGetter<KnowledgeBaseAnswerVisibilitySchedules>,
) => {
  const reactiveNow = useReactiveNow()

  // Every change that is still ahead, and the next of them - one clock for both, so a badge and the
  //   list behind it can never disagree about whether a change has already happened.
  const pendingVisibilitySchedules = computed(
    () =>
      toValue(answer).visibilitySchedules?.filter(
        ({ scheduledAt }) => new Date(scheduledAt).getTime() > reactiveNow.value.getTime(),
      ) ?? [],
  )

  const nextVisibilitySchedule = computed(() => pendingVisibilitySchedules.value[0])

  return { nextVisibilitySchedule, pendingVisibilitySchedules }
}
