<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'
import { TicketState } from '@shared/entities/ticket/types'

// TODO: Add a test and story for this common component.

export interface Props {
  status?: TicketState | string
  label: string
  pill?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  pill: false,
})

const states = new Set<string>(Object.values(TicketState))

const statusIndicator = computed(() => {
  if (!props.status || !states.has(props.status)) {
    return ''
  }

  return `state-${props.status}`
})
</script>

<template>
  <div
    :class="{
      'status-pill': pill,
      [`status-${status}`]: pill,
    }"
    class="flex select-none items-center"
    role="group"
  >
    <img
      v-if="statusIndicator"
      :src="`/assets/images/icons/${statusIndicator}.svg`"
      :alt="label"
      :width="pill ? 18 : 24"
      :height="pill ? 18 : 24"
    />
    <div v-if="pill" class="ml-[2px] text-xs uppercase leading-[14px]">
      {{ label }}
    </div>
  </div>
</template>

<style scoped lang="scss">
.status {
  &-pill {
    @apply rounded bg-gray-100 py-1 pr-1.5 pl-1 text-black;
  }

  &-closed {
    @apply bg-green-highlight text-green;
  }

  &-waiting-for-closure,
  &-waiting-for-reminder {
    @apply bg-gray-highlight text-gray;
  }

  &-open {
    @apply bg-yellow-highlight text-yellow;
  }

  &-escalated {
    @apply bg-red-highlight text-red;
  }
}
</style>
