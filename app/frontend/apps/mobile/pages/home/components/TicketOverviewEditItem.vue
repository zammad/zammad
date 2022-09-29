<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

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
      name: 'plus-small',
      class: 'bg-green',
    }
  }

  return {
    name: 'minus-small',
    class: 'bg-red',
  }
})
</script>

<template>
  <div
    class="flex min-h-[54px] items-center border-b border-gray-300 last:border-0"
    data-test-id="overviewItem"
  >
    <div
      class="flex h-5 w-5 cursor-pointer items-center justify-center rounded-full text-gray-500 ltr:mr-2 rtl:ml-2"
      :class="icon.class"
      @click="emit('action')"
    >
      <CommonIcon :name="icon.name" size="tiny" />
    </div>
    <div class="flex-1">
      {{ $t(overview.name) }}
    </div>
    <CommonIcon
      v-if="draggable"
      name="draggable"
      size="small"
      class="handler cursor-move text-white/30 ltr:mr-4 rtl:ml-4"
    />
  </div>
</template>
