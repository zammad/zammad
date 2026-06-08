<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import type { HistoryRecordEvent } from '#shared/graphql/types.ts'

import HistoryEventDetails from './HistoryEventDetails/HistoryEventDetails.vue'
import { useHistoryEvents } from './useHistoryEvents.ts'

interface Props {
  event: HistoryRecordEvent
}

const { event } = defineProps<Props>()

const { getEventOutput } = useHistoryEvents()

const eventDetails = getEventOutput(event)
</script>

<template>
  <div class="px-2">
    <component :is="eventDetails.component" v-if="eventDetails.component" :event="eventDetails" />
    <HistoryEventDetails v-else :event="eventDetails" />
  </div>
</template>
