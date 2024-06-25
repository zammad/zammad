<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import type { TicketDuplicateDetectionItem } from '#shared/entities/ticket/types.ts'

interface Props {
  tickets?: TicketDuplicateDetectionItem[]
}

defineProps<Props>()
</script>

<template>
  <CommonAlert variant="warning">
    <div class="flex flex-col gap-1.5">
      <CommonLabel class="text-yellow-600" size="large">
        {{ $c.ticket_duplicate_detection_title }}
      </CommonLabel>
      <CommonLabel class="text-yellow-600">
        {{ $c.ticket_duplicate_detection_body }}
      </CommonLabel>
      <ul
        v-for="[id, number, title] in tickets"
        :key="id"
        class="list-inside list-disc"
      >
        <li>
          <CommonLabel class="text-yellow-600"
            ><CommonLink
              :link="`/tickets/${id}`"
              class="text-yellow-600 !underline"
              >{{ number }}</CommonLink
            >
            {{ title }}</CommonLabel
          >
        </li>
      </ul>
    </div>
  </CommonAlert>
</template>
