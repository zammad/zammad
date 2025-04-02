<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import CommonTooltip from '#shared/components/CommonTooltip/CommonTooltip.vue'
import type { TooltipItemDescriptor } from '#shared/components/CommonTooltip/types.ts'

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

const hasTooltip = computed(
  () => props.overview.organizationShared || props.overview.outOfOffice,
)

const tooltipMessages = computed(() => {
  const messages: TooltipItemDescriptor[] = []

  if (props.overview.organizationShared)
    messages.push({
      type: 'text',
      label: __(
        'This overview is visible only when you are a shared organization member.',
      ),
    })

  if (props.overview.outOfOffice)
    messages.push({
      type: 'text',
      label: __(
        'This overview is visible only when you are an out of office replacement.',
      ),
    })

  return messages
})
</script>

<template>
  <div
    class="flex min-h-[54px] cursor-move items-center gap-2 border-b border-gray-300 p-3 last:border-0"
    data-test-id="overviewItem"
    :draggable="draggable ? 'true' : undefined"
  >
    <div
      class="shrink-0 cursor-pointer items-center justify-center"
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
    <div class="flex flex-1 items-center gap-2">
      <span class="truncate">{{ $t(overview.name) }}</span>
      <CommonTooltip
        v-if="hasTooltip"
        class="shrink-0"
        name="visibility"
        :messages="tooltipMessages"
        :heading="__('Limited Visibility')"
      >
        <CommonIcon name="tooltip" size="small" />
      </CommonTooltip>
    </div>
    <CommonIcon
      v-if="draggable"
      name="change-order"
      size="small"
      class="text-gray shrink-0"
    />
  </div>
</template>
