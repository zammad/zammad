<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, toRef } from 'vue'

import { useApplicationStore } from '#shared/stores/application.ts'

import CommonTicketPriorityIndicatorIcon from '#desktop/components/CommonTicketPriorityIndicator/CommonTicketPriorityIndicatorIcon.vue'
import CommonTicketStateIndicatorIcon from '#desktop/components/CommonTicketStateIndicator/CommonTicketStateIndicatorIcon.vue'

import { useTicketBulkEdit } from '../TicketBulkEditFlyout/useTicketBulkEdit.ts'

import type { DragPreviewData } from './types'

export interface Props {
  cursorPosition: {
    x: number
    y: number
  }
  previewData?: DragPreviewData | null
}

defineProps<Props>()

const config = toRef(useApplicationStore(), 'config')

const { currentSelectedTicketCount } = useTicketBulkEdit()

const remainingCount = computed(() => Math.max(0, currentSelectedTicketCount.value - 1))
const stackCount = computed(() => Math.min(currentSelectedTicketCount.value, 3))
</script>

<template>
  <div
    class="pointer-events-none fixed z-50"
    :style="{
      left: `${cursorPosition.x - 16}px`,
      top: `${cursorPosition.y - 32}px`,
    }"
  >
    <div class="relative">
      <div
        v-if="stackCount >= 3"
        data-test-id="3"
        class="absolute inset-s-5 top-0 h-10 w-full -translate-y-5 rounded-md bg-blue-50/25 dark:bg-gray-800/25"
      />
      <div
        v-if="stackCount >= 2"
        data-test-id="2"
        class="absolute inset-s-2.5 top-0 h-10 w-full -translate-y-2.5 rounded-md bg-blue-200/50 dark:bg-gray-700/50"
      />

      <div
        class="relative flex h-10 max-w-80 items-center gap-2 rounded-md border border-neutral-100 bg-blue-800 p-3 text-white! shadow-lg dark:border-gray-900"
      >
        <CommonIcon name="check-square" size="xs" class="shrink-0" />
        <CommonTicketPriorityIndicatorIcon
          v-if="config.ui_ticket_priority_icons"
          :ui-color="previewData?.priorityUiColor"
          class="m-0! shrink-0"
        />
        <CommonTicketStateIndicatorIcon
          v-if="previewData?.stateColorCode"
          class="mx-1 shrink-0 text-current!"
          :color-code="previewData.stateColorCode"
          icon-size="tiny"
        />
        <CommonLabel class="block! truncate text-sm text-current!">
          {{ previewData?.columnText }}
        </CommonLabel>
        <CommonLabel v-if="remainingCount > 0" class="shrink-0 text-sm text-current!">
          {{ $t('+ %s more', remainingCount) }}
        </CommonLabel>
      </div>
    </div>
  </div>
</template>
