<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import CommonPopoverWithTrigger from '#desktop/components/CommonPopover/CommonPopoverWithTrigger.vue'

import ChatCountBadge from './ChatCountBadge.vue'

interface Props {
  label: string
  count: number
  // The icon-only trigger has no text of its own.
  triggerLabel: string
  highlight?: boolean
  // Label and count take the next waiting customer, like in the old interface.
  acceptable?: boolean
  acceptDisabled?: boolean
  // Why the tab takes no customer, in place of its hint.
  acceptDisabledReason?: string
}

const props = defineProps<Props>()

const emit = defineEmits<{
  accept: []
}>()

const isAcceptActive = computed(() => props.acceptable && !props.acceptDisabled)

const acceptHint = computed(() => {
  if (!props.acceptable) return undefined

  return props.acceptDisabledReason ?? __('Accept next')
})
</script>

<template>
  <div
    class="flex items-center gap-1 rounded-full px-3.5 py-1"
    :class="{ 'bg-white dark:bg-gray-200': isAcceptActive }"
  >
    <component
      :is="acceptable ? 'button' : 'div'"
      v-tooltip.supportive="acceptHint && $t(acceptHint)"
      :type="acceptable ? 'button' : undefined"
      :aria-disabled="acceptable && acceptDisabled ? 'true' : undefined"
      class="flex items-center gap-1 rounded-full focus-visible-app-default"
      :class="{ 'cursor-pointer': isAcceptActive }"
      @click="isAcceptActive && emit('accept')"
    >
      <CommonLabel size="large" class="text-contrast">{{ label }}</CommonLabel>
      <ChatCountBadge :count="count" :highlight="highlight" />
    </component>
    <CommonPopoverWithTrigger
      class="rounded-full outline-offset-1 focus-visible:outline-2"
      orientation="bottom"
      placement="arrowStart"
      wide
      :aria-label="triggerLabel"
    >
      <template #popover-content>
        <div class="max-h-96 w-max min-w-72 overflow-y-auto p-3">
          <slot />
        </div>
      </template>

      <CommonIcon name="info-circle" size="xs" decorative />
    </CommonPopoverWithTrigger>
  </div>
</template>
