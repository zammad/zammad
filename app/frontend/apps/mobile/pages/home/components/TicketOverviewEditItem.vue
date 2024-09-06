<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import type { TicketOverview } from '#mobile/entities/ticket/stores/ticketOverviews.ts'

const props = defineProps<{
  action: 'add' | 'delete'
  draggable?: boolean
  overview: TicketOverview
}>()

const emit = defineEmits<{
  action: []
  'action-active': [boolean]
}>()

const icon = computed(() => {
  if (props.action === 'add') {
    return {
      name: 'plus',
      class: 'text-green',
    }
  }

  return {
    name: 'minus',
    class: 'text-red',
  }
})
</script>

<template>
  <div
    class="flex min-h-[54px] cursor-move items-center border-b border-gray-300 last:border-0"
    data-test-id="overviewItem"
    :draggable="draggable ? 'true' : undefined"
  >
    <div
      class="ms-3 shrink-0 cursor-pointer items-center justify-center ltr:mr-2 rtl:ml-2"
      :class="icon.class"
      role="button"
      tabindex="0"
      @keydown.enter="emit('action')"
      @click="emit('action')"
      @mousedown="emit('action-active', true)"
      @mouseup="emit('action-active', false)"
      @mouseout="emit('action-active', false)"
      @focusout="emit('action-active', false)"
      @blur="emit('action-active', false)"
      @touchstart="emit('action-active', true)"
      @touchend="emit('action-active', false)"
      @touchcancel="emit('action-active', false)"
    >
      <CommonIcon :name="icon.name" size="base" />
    </div>
    <div class="flex-1">
      {{ $t(overview.name) }}
    </div>
    <CommonIcon
      v-if="draggable"
      name="change-order"
      size="small"
      class="text-gray shrink-0 ltr:mr-4 rtl:ml-4"
    />
  </div>
</template>
