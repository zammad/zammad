<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import type { CalendarIcsFileEventsQuery } from '#shared/graphql/types.ts'
import { textToHtml } from '#shared/utils/helpers.ts'

import CommonEntityAttribute from '#desktop/components/CommonEntityAttribute/CommonEntityAttribute.vue'

interface Props {
  event: CalendarIcsFileEventsQuery['calendarIcsFileEvents'][number]
}

defineProps<Props>()
</script>

<template>
  <article class="flex flex-col gap-3">
    <CommonLabel v-if="event.title" tag="h3" size="large" class="font-semibold text-contrast!">
      {{ event.title }}
    </CommonLabel>

    <!-- eslint-disable vue/no-v-html -->
    <CommonEntityAttribute v-if="event.location" :label="__('Location')">
      <div v-html="textToHtml(event.location)" />
    </CommonEntityAttribute>

    <div class="grid grid-cols-1 gap-3 @sm:grid-cols-2">
      <CommonEntityAttribute v-if="event.startDate" :label="__('Start date')">
        <CommonDateTime :date-time="event.startDate" type="absolute" />
      </CommonEntityAttribute>

      <CommonEntityAttribute v-if="event.endDate" :label="__('End date')">
        <CommonDateTime :date-time="event.endDate" type="absolute" />
      </CommonEntityAttribute>
    </div>

    <div
      v-if="event.organizer || event.attendees?.length"
      class="grid grid-cols-1 gap-3 @sm:grid-cols-2"
    >
      <CommonEntityAttribute v-if="event.organizer" :label="__('Organizer')">
        <div v-html="textToHtml(event.organizer)" />
      </CommonEntityAttribute>

      <CommonEntityAttribute v-if="event.attendees?.length" :label="__('Attendees')">
        <ul class="list-disc ps-4">
          <li
            v-for="(attendee, index) in event.attendees"
            :key="index"
            v-html="textToHtml(attendee)"
          />
        </ul>
      </CommonEntityAttribute>
    </div>

    <CommonEntityAttribute v-if="event.description" :label="__('Description')">
      <div v-html="textToHtml(event.description)" />
    </CommonEntityAttribute>
    <!-- eslint-enable vue/no-v-html -->
  </article>
</template>
