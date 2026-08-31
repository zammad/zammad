<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import CommonDateTime from '#shared/components/CommonDateTime/CommonDateTime.vue'
import {
  NotificationTypes,
  useNotifications,
} from '#shared/components/CommonNotifications/index.ts'
import { useConfirmation } from '#shared/composables/useConfirmation.ts'
import { useTouchDevice } from '#shared/composables/useTouchDevice.ts'
import { EnumKnowledgeBaseSchedulableVisibility } from '#shared/graphql/types.ts'
import type { EnumKnowledgeBaseVisibility } from '#shared/graphql/types.ts'
import { i18n } from '#shared/i18n.ts'
import { MutationHandler } from '#shared/server/apollo/handler/index.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import { useFlyout } from '#desktop/components/CommonFlyout/useFlyout.ts'
import CommonSectionCollapse from '#desktop/components/CommonSectionCollapse/CommonSectionCollapse.vue'
import { visibilityMeta } from '#desktop/components/KnowledgeBaseAnswerIcon/visibilityMeta.ts'
import { useKnowledgeBaseAnswerVisibilityScheduleRemoveMutation } from '#desktop/entities/knowledge-base/graphql/mutations/knowledgeBaseAnswerVisibilityScheduleRemove.api.ts'

import type { KnowledgeBaseAnswerHeader } from '../../../types.ts'

interface Props {
  answer: KnowledgeBaseAnswerHeader
  // A schedule is written onto the answer the moment it is removed - so like the tags and the
  //   related tickets it is not a form value: nothing about it is submitted with the edit form, it
  //   is no part of the auto-saved draft, and "Discard your unsaved changes" does not bring a
  //   removed entry back.
  editable?: boolean
}

const props = withDefaults(defineProps<Props>(), { editable: false })

// Null rather than empty for anybody but an editor of the category: the field is denied to them
//   (KnowledgeBase::AnswerPolicy#show?), so it arrives absent rather than as "none scheduled".
//   Treated as empty here all the same - the section is only rendered for an editor, so this covers
//   the moment before the answer has resolved rather than a real difference.
const schedules = computed(() => props.answer.visibilitySchedules ?? [])

const { notify } = useNotifications()
const { isTouchDevice } = useTouchDevice()
const { waitForConfirmation } = useConfirmation()

// The two enums name the same states, and their generated values are identical: the schedulable one
//   is the answer's own visibility without `draft`, which stores no date and can therefore not be
//   scheduled. TypeScript keeps them apart all the same, so the lookup into the shared
//   icon/colour/label map is bridged here rather than at every use.
const metaFor = (visibility: EnumKnowledgeBaseSchedulableVisibility) =>
  visibilityMeta[visibility as unknown as EnumKnowledgeBaseVisibility]

// `archived`'s own colour is a dim neutral, which is what makes it read as *inactive* in the answer
//   list - and as too faint to read here, where it is carrying a whole line of text rather than
//   tinting a small icon. So it keeps the default label colour, and only the states with a real hue
//   are tinted (`internal` blue, `published` green).
const colorFor = (visibility: EnumKnowledgeBaseSchedulableVisibility) =>
  visibility === EnumKnowledgeBaseSchedulableVisibility.Archived
    ? undefined
    : metaFor(visibility).class

const removeMutation = new MutationHandler(
  useKnowledgeBaseAnswerVisibilityScheduleRemoveMutation({}),
  { errorNotificationMessage: __('The scheduled visibility change could not be removed.') },
)

const scheduleFlyout = useFlyout({
  name: 'knowledge-base-answer-visibility-schedule',
  component: () => import('./KnowledgeBaseAnswerVisibilityScheduleFlyout.vue'),
})

const openScheduleFlyout = () => scheduleFlyout.open({ answerId: props.answer.id })

// Asked before it is gone rather than offered back afterwards: there is no undo for it - the date
//   is only stored on the answer, so putting the change back means picking a new one in the flyout.
//   Which state it is about is named in the prompt, since the pills sit close together and each
//   button is only revealed on hover.
//
// The `delete` variant for the trash icon and the danger button, with its generic "Delete object"
//   header overridden - the same shape as the category delete, whose prompt names its record too.
const confirmRemoval = (visibility: EnumKnowledgeBaseSchedulableVisibility) =>
  waitForConfirmation(__('Do you really want to remove the scheduled change to %s?'), {
    confirmationVariant: 'delete',
    headerTitle: __('Remove scheduled visibility change'),
    // Translated here: the dialog inserts a placeholder as it is, and this one is UI copy rather
    //   than data (`visibilityMeta` keeps the label untranslated, next to icon and colour).
    textPlaceholder: [i18n.t(metaFor(visibility).label)],
    // The header already says what is being removed, and a plain "Remove" is a string the catalog
    //   has - no near-duplicate needed for it.
    buttonLabel: __('Remove'),
  })

// No cache write of its own, unlike the tag section above: the mutation renders the answer's
//   remaining schedule back, and the normalized entity that lands in is the one this list reads.
//
// The mutation is idempotent - an entry somebody else removed, or one that has been reached in the
//   meantime, is not an error - so a stale pill simply disappears instead of reporting a failure.
const removeSchedule = async (visibility: EnumKnowledgeBaseSchedulableVisibility) => {
  if (!(await confirmRemoval(visibility))) return

  const result = await removeMutation.send({ answerId: props.answer.id, visibility })

  if (!result?.knowledgeBaseAnswerVisibilityScheduleRemove?.answer) return

  notify({
    id: 'knowledge-base-answer-visibility-schedule-removed',
    type: NotificationTypes.Success,
    message: __('Scheduled visibility change removed successfully.'),
  })
}
</script>

<template>
  <CommonSectionCollapse
    id="knowledge-base-scheduled-visibility"
    :title="__('Scheduled visibility')"
  >
    <template #default="{ headerId }">
      <div class="flex flex-col gap-2">
        <ul
          v-if="schedules.length"
          :aria-labelledby="headerId"
          class="flex w-full flex-col rounded-lg bg-blue-200 px-2.5 dark:bg-gray-700"
        >
          <li
            v-for="schedule in schedules"
            :key="schedule.visibility"
            class="group flex items-center gap-1.5 py-2.5"
          >
            <!-- One clock for every state, rather than the state icons the answer list and the
                 taskbar tab show - and tinted with the state's colour where it has one, which is
                 what the design has. See #colorFor for why `archived` does not get its own. -->
            <CommonLabel
              class="grow"
              prefix-icon="clock"
              :icon-color="colorFor(schedule.visibility)"
            >
              <span :class="colorFor(schedule.visibility)">
                {{ $t(metaFor(schedule.visibility).label) }}
              </span>

              <!-- Relative, like every other date of this sidebar (the publication dates above),
                   and what the design shows: "in 2 days". -->
              <CommonDateTime :date-time="schedule.scheduledAt" type="relative" />
            </CommonLabel>

            <!-- Hover-only on a pointer device, always there on a touch one, which has no hover to
                 reveal it with. -->
            <CommonButton
              v-if="editable"
              v-tooltip="$t('Remove this scheduled visibility change')"
              :class="{ 'opacity-0 transition-opacity': !isTouchDevice }"
              class="group-hover:opacity-100 focus:opacity-100"
              icon="x-lg"
              size="small"
              variant="remove"
              @click.stop="removeSchedule(schedule.visibility)"
            />
          </li>
        </ul>

        <CommonLabel v-else size="small">
          {{ $t('No visibility changes scheduled yet.') }}
        </CommonLabel>

        <!-- `v-tooltip` supplies the accessible name of an icon-only button, which the directive
             writes into `aria-label`. -->
        <CommonButton
          v-if="editable"
          v-tooltip="$t('Schedule visibility change')"
          size="medium"
          class="self-end"
          icon="plus-square-fill"
          @click="openScheduleFlyout"
        />
      </div>
    </template>
  </CommonSectionCollapse>
</template>
