<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'
import type { TicketOverview } from '@mobile/entities/ticket/stores/ticketOverviews'

const props = defineProps<{
  action: 'add' | 'delete'
  draggable?: boolean
  overview: TicketOverview
}>()

const emit = defineEmits<{
  (e: 'action'): void
}>()

const icon = computed(() => {
  if (props.action === 'add') {
    return {
      name: 'mobile-plus',
      class: 'text-green',
    }
  }

  return {
    name: 'mobile-minus',
    class: 'text-red',
  }
})
</script>

<template>
  <div
    class="flex min-h-[54px] items-center border-b border-gray-300 last:border-0"
    data-test-id="overviewItem"
  >
    <div
      class="shrink-0 cursor-pointer items-center justify-center ltr:mr-2 rtl:ml-2"
      :class="icon.class"
      @click="emit('action')"
    >
      <CommonIcon :name="icon.name" size="base" />
    </div>
    <div class="flex-1">
      {{ $t(overview.name) }}
    </div>
    <CommonIcon
      v-if="draggable"
      name="mobile-change-order"
      size="small"
      class="handler shrink-0 cursor-move text-gray ltr:mr-4 rtl:ml-4"
    />
  </div>
</template>
