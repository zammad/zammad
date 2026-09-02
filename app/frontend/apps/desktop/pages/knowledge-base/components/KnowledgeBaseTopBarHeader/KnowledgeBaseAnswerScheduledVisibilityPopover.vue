<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import type { EnumKnowledgeBaseSchedulableVisibility } from '#shared/graphql/types.ts'
import getUuid from '#shared/utils/getUuid.ts'

import KnowledgeBaseAnswerScheduledVisibilityItem from '../KnowledgeBaseAnswerScheduledVisibilityItem/KnowledgeBaseAnswerScheduledVisibilityItem.vue'

// Every change the answer is going to make, where the badge that opens this shows only the next of
//   them. Read-only: scheduling and removing stay with the editor's sidebar section, which is the
//   other user of the row component below.
interface Props {
  id?: string
  schedules: {
    visibility: EnumKnowledgeBaseSchedulableVisibility
    scheduledAt: string
  }[]
}

defineProps<Props>()

// The list names its own heading rather than the badge that opens the popover: what the reader needs
//   is what this list *is*, and the badge's label only repeats its first row.
const headingId = `knowledge-base-scheduled-visibility-${getUuid()}`
</script>

<template>
  <section :id="id" data-type="popover" class="flex flex-col gap-3 p-3">
    <CommonLabel :id="headingId" tag="h3" size="small" class="text-stone-200 dark:text-neutral-500">
      {{ $t('Scheduled visibility') }}
    </CommonLabel>

    <ul class="flex flex-col gap-5" :aria-labelledby="headingId">
      <KnowledgeBaseAnswerScheduledVisibilityItem
        v-for="schedule in schedules"
        :key="schedule.visibility"
        class="py-0!"
        :visibility="schedule.visibility"
        :scheduled-at="schedule.scheduledAt"
      />
    </ul>
  </section>
</template>
