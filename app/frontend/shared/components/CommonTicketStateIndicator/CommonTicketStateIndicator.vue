<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

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

const statusIndicator = computed(() => {
  switch (props.status) {
    case TicketState.Closed:
      return 'mobile-check-circle-outline'
    case TicketState.WaitingForClosure:
      return 'mobile-check-circle-outline-dashed'
    case TicketState.WaitingForReminder:
      return 'mobile-check-circle-outline-dashed'
    case TicketState.Escalated:
      return 'mobile-warning-triangle'
    case TicketState.New:
    case TicketState.Open:
    default:
      return 'mobile-check-circle-no'
  }
})
</script>

<template>
  <div
    :class="{
      'status-pill': pill,
      [`status-${status}`]: true,
    }"
    class="status flex select-none items-center"
    role="group"
  >
    <CommonIcon
      v-if="statusIndicator"
      :name="statusIndicator"
      :size="pill ? 'tiny' : 'base'"
      decorative
    />
    <div v-if="pill" class="ml-[2px] text-xs uppercase leading-[14px]">
      {{ label }}
    </div>
  </div>
</template>

<style scoped lang="scss">
.status {
  @apply text-gray;

  &-pill {
    @apply rounded bg-gray-100 py-1 pr-1.5 pl-1 text-black;

    &.status-closed {
      @apply bg-green-highlight;
    }

    &.status-merged,
    &.status-removed,
    &.status-waiting-for-closure,
    &.status-waiting-for-reminder {
      @apply bg-gray-highlight;
    }

    &.status-new,
    &.status-open {
      @apply bg-yellow-highlight;
    }

    &.status-escalated {
      @apply bg-red-highlight;
    }
  }

  &-closed {
    @apply text-green;
  }

  &-waiting-for-closure,
  &-waiting-for-reminder {
    @apply text-gray;
  }

  &-new,
  &-open {
    @apply text-yellow;
  }

  &-escalated {
    @apply text-red;
  }
}
</style>
