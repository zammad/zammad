<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

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
      <CommonLabel class="text-yellow-700! dark:text-yellow-300!" size="large">
        {{ $c.ticket_duplicate_detection_title }}
      </CommonLabel>
      <CommonLabel class="text-yellow-700! dark:text-yellow-300!">
        {{ $c.ticket_duplicate_detection_body }}
      </CommonLabel>
      <ul v-for="[id, number, title] in tickets" :key="id" class="list-inside list-disc">
        <li>
          <CommonLabel class="text-yellow-700! dark:text-yellow-300!">
            <CommonLink
              :link="`/tickets/${id}`"
              class="text-yellow-700! underline hover:text-yellow-700! hover:underline! dark:text-yellow-300! hover:dark:text-yellow-500!"
              size="medium"
            >
              {{ number }}
            </CommonLink>
            {{ title }}
          </CommonLabel>
        </li>
      </ul>
    </div>
  </CommonAlert>
</template>
