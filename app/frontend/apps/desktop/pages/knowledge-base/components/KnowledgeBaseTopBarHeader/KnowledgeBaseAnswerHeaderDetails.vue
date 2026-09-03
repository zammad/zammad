<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import type { BadgeVariant } from '#shared/components/CommonBadge/types.ts'
import CommonDateTime from '#shared/components/CommonDateTime/CommonDateTime.vue'
import { userDisplayName } from '#shared/entities/user/utils/getUserDisplayName.ts'
import { EnumKnowledgeBaseVisibility } from '#shared/graphql/types.ts'
import { i18n } from '#shared/i18n.ts'
import { useSessionStore } from '#shared/stores/session.ts'

import CommonPopoverWithTrigger from '#desktop/components/CommonPopover/CommonPopoverWithTrigger.vue'
import KnowledgeBaseAnswerIcon from '#desktop/components/KnowledgeBaseAnswerIcon/KnowledgeBaseAnswerIcon.vue'
import { visibilityMeta } from '#desktop/components/KnowledgeBaseAnswerIcon/visibilityMeta.ts'
import { useKnowledgeBaseAnswerReachedDates } from '#desktop/entities/knowledge-base/composables/useKnowledgeBaseAnswerReachedDates.ts'

import { useKnowledgeBaseAnswerNextVisibilitySchedule } from '../../composables/useKnowledgeBaseAnswerNextVisibilitySchedule.ts'

import KnowledgeBaseAnswerScheduledVisibilityPopover from './KnowledgeBaseAnswerScheduledVisibilityPopover.vue'

import type { KnowledgeBaseAnswerHeaderDetailsAnswer } from './types.ts'

const props = defineProps<{ answer: KnowledgeBaseAnswerHeaderDetailsAnswer }>()

const session = useSessionStore()

// The badge picks up the state color of the icon it carries, so the strip reads
//   the same as the answer list.
const badgeVariants: Record<EnumKnowledgeBaseVisibility, BadgeVariant> = {
  [EnumKnowledgeBaseVisibility.Draft]: 'tertiary',
  [EnumKnowledgeBaseVisibility.Internal]: 'info',
  [EnumKnowledgeBaseVisibility.Published]: 'success',
  [EnumKnowledgeBaseVisibility.Archived]: 'tertiary',
}

// The state the badge names and the date it was reached at, both off the *reached* dates rather
//   than the raw fields: a publication scheduled for next week can neither date nor rename a badge
//   that still says "DRAFT". What is still ahead belongs to the scheduled badge below, and to
//   nobody who may not edit the answer.
const { reachedDate, reachedVisibility } = useKnowledgeBaseAnswerReachedDates(() => props.answer)

// The clock rather than `answer.visibility`, which the server derives once per request and which
//   therefore keeps naming the state the answer was in when the page loaded - so a schedule falling
//   due while it stays open would leave a green "PUBLISHED" badge dated with the archival it has
//   just reached. Both halves move together now.
//
// Falling back to the field for an answer that has reached no date at all, which is the one case
//   the dates cannot name: that is a draft for a stored answer, but the create header has no stored
//   answer at all and passes the visibility being picked in the form (see its `visibility` prop).
const visibility = computed(() => reachedVisibility.value ?? props.answer.visibility)

// The bare timestamp, the way the edit chip at the foot of the strip and `CommonDateTime` itself
//   render theirs: the badge already names the state in its own text, so repeating the state here
//   would say it twice.
const reachedTooltip = computed(() =>
  reachedDate.value ? i18n.dateTime(reachedDate.value) : undefined,
)

// And the other half of the same clock: the next state the answer is going to reach. Absent for
//   anybody who may not edit it, which is the whole of the permission check here - see the
//   composable for why this component has none of its own.
const { nextVisibilitySchedule, pendingVisibilitySchedules } =
  useKnowledgeBaseAnswerNextVisibilitySchedule(() => props.answer)

// Bridged once here rather than at both lookups below: the two enums name the same states
//   with identical values - the schedulable one is the answer's visibility without `draft`, which
//   stores no date and can therefore not be scheduled - and TypeScript keeps them apart all the
//   same.
const nextSchedule = computed(() => {
  const schedule = nextVisibilitySchedule.value

  if (!schedule) return undefined

  return {
    scheduledAt: schedule.scheduledAt,
    visibility: schedule.visibility,
  }
})

// What the badge says, for whoever cannot see it. `role="button"` makes the trigger's children
//   presentational, so the badge's own text is dropped from the accessibility tree rather than just
//   outranked - without this the announced name would be the popover's title alone, and the state
//   and its timing would only be reachable by opening the popover.
const nextScheduleLabel = computed(() => {
  const schedule = nextSchedule.value

  if (!schedule) return undefined

  return i18n.t(
    'Scheduled visibility: %s',
    `${i18n.t(visibilityMeta[schedule.visibility].label)} ${i18n.relativeDateTime(schedule.scheduledAt)}`,
  )
})

// Deliberately a fixed value: the chip is rendered once per answer load, so it
//   does not track elapsed time the way the CommonDateTime badges above do.
const editedLabel = computed(() => {
  const { editedAt, editedBy } = props.answer.translation ?? {}

  if (!editedAt) return undefined

  const date = i18n.relativeDateTime(editedAt)

  // Checked before the identity comparison: without an editor both sides would
  //   be `undefined` and the chip would claim the current user edited it.
  if (!editedBy) return i18n.t('edited %s', date)

  if (editedBy.id === session.user?.id) return i18n.t('edited %s by me', date)

  return i18n.t('edited %s by %s', date, userDisplayName(editedBy))
})

const editedTooltip = computed(() => {
  const editedAt = props.answer.translation?.editedAt

  return editedAt ? i18n.dateTime(editedAt) : undefined
})
</script>

<template>
  <div class="flex max-w-full flex-wrap items-center gap-2.5 text-nowrap *:h-7">
    <!-- `.supportive`, so the date lands in `aria-description` beside the badge's own text rather
         than replacing it as an `aria-label`: the badge visibly reads "INTERNAL" where the
         timestamp label is "Internally published", and a plain tooltip would make the two
         disagree. Same choice as the edit chip at the foot of the strip. -->
    <CommonBadge
      v-tooltip.supportive="reachedTooltip"
      :variant="badgeVariants[visibility]"
      class="gap-1 uppercase"
    >
      <KnowledgeBaseAnswerIcon decorative :visibility="visibility" size="tiny" />
      {{ $t(visibilityMeta[visibility].label) }}
    </CommonBadge>

    <CommonPopoverWithTrigger
      v-if="nextSchedule"
      class="flex rounded-md outline-offset-1 focus-visible:outline-2"
      placement="arrowStart"
      orientation="bottom"
      trigger-link-active-class="outline-blue-800! outline-2!"
      :aria-label="nextScheduleLabel"
    >
      <!-- The clock-filtered list rather than the field as it arrived, so the rows and the badge
           in front of them agree about what has already happened. -->
      <template #popover-content="{ popoverId }">
        <KnowledgeBaseAnswerScheduledVisibilityPopover
          :id="popoverId"
          :schedules="pendingVisibilitySchedules"
        />
      </template>

      <!-- The forward-looking visibility badge: the next date the answer is going to reach,
           which is why it carries the target state's own color where they share a neutral grey
           - the same `badgeVariants` the visibility badge resolves, so a scheduled state is tinted
           here exactly as it will be once it arrives. -->
      <CommonBadge
        class="cursor-pointer gap-1 uppercase"
        :variant="badgeVariants[nextSchedule.visibility]"
      >
        <CommonIcon name="eye" size="tiny" decorative />
        <CommonDateTime :date-time="nextSchedule.scheduledAt" type="relative">
          <template #prefix>
            {{ $t(visibilityMeta[nextSchedule.visibility].label) }}
          </template>
        </CommonDateTime>
      </CommonBadge>
    </CommonPopoverWithTrigger>

    <CommonBadge
      v-if="editedLabel"
      v-tooltip.supportive="editedTooltip"
      variant="tertiary"
      class="uppercase"
    >
      {{ editedLabel }}
    </CommonBadge>
  </div>
</template>
