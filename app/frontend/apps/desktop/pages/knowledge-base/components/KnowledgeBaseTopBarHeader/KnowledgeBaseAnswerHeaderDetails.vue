<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import type { BadgeVariant } from '#shared/components/CommonBadge/types.ts'
import CommonDateTime from '#shared/components/CommonDateTime/CommonDateTime.vue'
import { userDisplayName } from '#shared/entities/user/utils/getUserDisplayName.ts'
import { EnumKnowledgeBaseVisibility } from '#shared/graphql/types.ts'
import { i18n } from '#shared/i18n.ts'
import { useSessionStore } from '#shared/stores/session.ts'

import KnowledgeBaseAnswerIcon from '#desktop/components/KnowledgeBaseAnswerIcon/KnowledgeBaseAnswerIcon.vue'
import { visibilityMeta } from '#desktop/components/KnowledgeBaseAnswerIcon/visibilityMeta.ts'

import { useKnowledgeBaseAnswerReachedDates } from '../../composables/useKnowledgeBaseAnswerReachedDates.ts'

import type { KnowledgeBaseAnswerHeaderDetailsAnswer } from './types.ts'

const props = withDefaults(
  defineProps<{
    answer: KnowledgeBaseAnswerHeaderDetailsAnswer
    // Off by default: the reader's header docks the very same warning as an alert bar
    //   (KnowledgeBaseAnswerTopBarHeader's `alertMessage`), and showing both would say it twice.
    //   The edit header has no alert of its own, so there it is this badge or nothing.
    withTranslationWarning?: boolean
  }>(),
  { withTranslationWarning: false },
)

const session = useSessionStore()

// The badge picks up the state color of the icon it carries, so the strip reads
//   the same as the answer list.
const badgeVariants: Record<EnumKnowledgeBaseVisibility, BadgeVariant> = {
  [EnumKnowledgeBaseVisibility.Draft]: 'tertiary',
  [EnumKnowledgeBaseVisibility.Internal]: 'info',
  [EnumKnowledgeBaseVisibility.Published]: 'success',
  [EnumKnowledgeBaseVisibility.Archived]: 'tertiary',
}

const visibility = computed(() => props.answer.visibility)

// Only the dates the answer has actually reached: this strip says what the answer is, not what it is
//   going to become - without the filter a draft whose publication is scheduled for next week would
//   claim "PUBLISHED IN 1 WEEK" here, in the reader's header as much as in the editor's.
const { reachedDates } = useKnowledgeBaseAnswerReachedDates(() => props.answer)

// Deliberately a fixed value: the chip is rendered once per answer load, so it
//   does not track elapsed time the way the CommonDateTime badges above do.
const editedLabel = computed(() => {
  const { editedAt, editedBy } = props.answer

  if (!editedAt) return undefined

  const date = i18n.relativeDateTime(editedAt)

  // Checked before the identity comparison: without an editor both sides would
  //   be `undefined` and the chip would claim the current user edited it.
  if (!editedBy) return i18n.t('edited %s', date)

  if (editedBy.id === session.user?.id) return i18n.t('edited %s by me', date)

  return i18n.t('edited %s by %s', date, userDisplayName(editedBy))
})

const editedTooltip = computed(() => {
  const { editedAt } = props.answer

  return editedAt ? i18n.dateTime(editedAt) : undefined
})
</script>

<template>
  <div class="flex max-w-full flex-wrap items-center gap-2.5 text-nowrap *:h-7">
    <CommonBadge :variant="badgeVariants[visibility]" class="gap-1 uppercase">
      <KnowledgeBaseAnswerIcon decorative :visibility="visibility" size="tiny" />
      {{ $t(visibilityMeta[visibility].label) }}
    </CommonBadge>

    <!-- Same warning the browse view's answer card carries next to an untranslated title. -->
    <CommonBadge
      v-if="withTranslationWarning && answer.translationMissing"
      v-tooltip="$t('No translation for this locale available')"
      variant="warning"
      size="xs"
      rounded
      class="flex items-center justify-center p-1!"
    >
      <CommonIcon name="translate" size="xs" decorative />
    </CommonBadge>

    <CommonBadge v-if="reachedDates.internalAt" variant="tertiary" class="uppercase">
      <CommonDateTime :date-time="reachedDates.internalAt" type="relative" class="ms-1">
        <template #prefix>
          {{ $t('Internally published') }}
        </template>
      </CommonDateTime>
    </CommonBadge>

    <CommonBadge v-if="reachedDates.publishedAt" variant="tertiary" class="uppercase">
      <CommonDateTime :date-time="reachedDates.publishedAt" type="relative" class="ms-1">
        <template #prefix>
          {{ $t('Published') }}
        </template>
      </CommonDateTime>
    </CommonBadge>

    <CommonBadge v-if="reachedDates.archivedAt" variant="tertiary" class="uppercase">
      <CommonDateTime :date-time="reachedDates.archivedAt" type="relative" class="ms-1">
        <template #prefix>
          {{ $t('Archived') }}
        </template>
      </CommonDateTime>
    </CommonBadge>

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
