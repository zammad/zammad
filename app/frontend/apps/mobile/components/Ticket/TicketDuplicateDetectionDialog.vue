<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonButton from '#mobile/components/CommonButton/CommonButton.vue'
import CommonDialog from '#mobile/components/CommonDialog/CommonDialog.vue'
import { closeDialog } from '#shared/composables/useDialog.ts'
import { useApplicationStore } from '#shared/stores/application.ts'
import type { TicketDuplicateDetectionItem } from '#mobile/pages/ticket/composable/useTicketDuplicateDetectionHandler.ts'

defineProps<{
  tickets: TicketDuplicateDetectionItem[]
}>()

const application = useApplicationStore()
</script>

<template>
  <CommonDialog class="w-full" name="duplicate-ticket-detection" no-autofocus>
    <template #before-label>
      <CommonButton
        transparent-background
        @click="closeDialog('duplicate-ticket-detection')"
      >
        {{ $t('Close') }}
      </CommonButton>
    </template>
    <template #after-label>
      <CommonButton
        variant="primary"
        transparent-background
        @click="closeDialog('duplicate-ticket-detection')"
      >
        {{ $t('OK') }}
      </CommonButton>
    </template>
    <div class="w-full p-4">
      <h3 class="mb-3 text-xl">
        {{ application.config.ticket_duplicate_detection_title }}
      </h3>
      <p class="mb-3 whitespace-pre-wrap break-words text-base">
        {{ application.config.ticket_duplicate_detection_body }}
      </p>
      <CommonLink
        v-for="ticket in tickets"
        :key="ticket[0]"
        :link="`/tickets/${ticket[0]}`"
      >
        <div class="flex cursor-pointer ltr:pr-3 rtl:pl-3">
          <div
            class="flex flex-1 items-center gap-1 overflow-hidden border-b border-white/10 py-3 text-gray-100 ltr:pr-2 rtl:pl-2"
          >
            <div class="flex-1 truncate">
              <span>#{{ ticket[1] }}</span>
              <span
                class="mb-1 line-clamp-3 whitespace-normal text-lg font-bold leading-5"
              >
                {{ ticket[2] }}
              </span>
            </div>
          </div>
        </div>
      </CommonLink>
    </div>
  </CommonDialog>
</template>
