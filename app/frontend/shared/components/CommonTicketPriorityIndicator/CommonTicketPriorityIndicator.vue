<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { i18n } from '@shared/i18n'
import { computed } from 'vue'
import type { TicketPriority } from './types'

interface Props {
  priority?: TicketPriority
}

const props = defineProps<Props>()

const definition = computed(() => {
  if (!props.priority || props.priority.defaultCreate) {
    return null
  }
  return {
    class: `u-${props.priority.uiColor || 'default'}-color`,
    text: i18n.t(props.priority.name).toUpperCase(),
  }
})
</script>

<template>
  <div
    v-if="definition"
    :class="[
      definition.class,
      'h-min select-none whitespace-nowrap rounded-[4px] py-1 px-2',
    ]"
  >
    {{ definition.text }}
  </div>
</template>

<style scoped lang="scss">
.u-default-color {
  @apply bg-gray/10 text-gray;
}

.u-high-priority-color {
  @apply bg-red-dark text-red-bright;
}

.u-low-priority-color {
  @apply bg-blue/10 text-blue;
}

.u-medium-priority-color {
  @apply bg-yellow/10 text-yellow;
}
</style>
