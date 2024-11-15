<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import type { HistoryRecordEvent } from '#shared/graphql/types.ts'

import { useHistoryEvents } from './composables/useHistoryEvents.ts'
import HistoryEventDetails from './HistoryEventDetails/HistoryEventDetails.vue'

interface Props {
  event: HistoryRecordEvent
}

const { event } = defineProps<Props>()

const { getEventOutput } = useHistoryEvents()

const eventDetails = getEventOutput(event)
</script>

<template>
  <div class="px-2">
    <CommonLabel
      class="rounded text-stone-200 ltr:mr-1 rtl:ml-1 dark:text-neutral-400"
    >
      {{ eventDetails.actionName }}
    </CommonLabel>

    <span>
      <component
        :is="eventDetails.component"
        v-if="eventDetails.component"
        :changes="eventDetails"
      />
      <HistoryEventDetails v-else :changes="eventDetails" />
    </span>
  </div>
</template>
