<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonDialog from '#mobile/components/CommonDialog/CommonDialog.vue'
import type { TicketDuplicateDetectionItem } from '#mobile/pages/ticket/composable/useTicketDuplicateDetectionHandler.ts'

defineProps<{
  name: string
  tickets: TicketDuplicateDetectionItem[]
}>()
</script>

<template>
  <CommonDialog
    :label="$c.ticket_duplicate_detection_title as string"
    class="w-full"
    :name="name"
    no-autofocus
  >
    <div class="w-full p-4">
      <p class="mb-3 whitespace-pre-wrap break-words">
        {{ $c.ticket_duplicate_detection_body }}
      </p>
      <CommonLink
        v-for="[id, number, title] in tickets"
        :key="id"
        :link="`/tickets/${id}`"
      >
        <div class="flex cursor-pointer ltr:pr-3 rtl:pl-3">
          <div
            class="flex flex-1 items-center gap-1 overflow-hidden border-b border-white/10 py-3 text-gray-100 ltr:pr-2 rtl:pl-2"
          >
            <div class="flex-1 truncate text-sm">
              <span>#{{ number }}</span>
              <span
                class="mb-1 line-clamp-3 whitespace-normal text-lg font-bold leading-5"
              >
                {{ title }}
              </span>
            </div>
          </div>
        </div>
      </CommonLink>
    </div>
  </CommonDialog>
</template>
