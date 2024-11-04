<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import CommonUpdateIndicator from '#desktop/components/CommonUpdateIndicator/CommonUpdateIndicator.vue'

import {
  TicketSidebarButtonBadgeType,
  type TicketSidebarButtonBadgeDetails,
} from '../../types/sidebar.ts'

interface Props {
  name: string
  label: string
  icon: string
  selected?: boolean
  badge?: TicketSidebarButtonBadgeDetails
  updateIndicator?: boolean
}

const props = defineProps<Props>()

defineEmits<{
  click: [string]
}>()

const processedBadgeValue = computed(() => {
  const value = props.badge?.value

  if (!value) return

  if (!(typeof value === 'number')) return value

  if (value > 99) return '99+'

  return value
})

const badgeColor = computed(() => {
  switch (props.badge?.type) {
    case TicketSidebarButtonBadgeType.Warning:
      return 'bg-yellow-500 text-yellow-100'
    case TicketSidebarButtonBadgeType.Danger:
      return 'bg-red-500 text-pink-100'
    case TicketSidebarButtonBadgeType.Info:
    default:
      return 'bg-pink-500 text-white'
  }
})
</script>

<template>
  <div class="relative">
    <CommonButton
      v-tooltip="$t(label)"
      :class="{
        'text-black outline outline-1 outline-offset-1 outline-blue-800 focus:outline focus:outline-1 focus:outline-offset-1 focus:outline-blue-800 dark:text-white':
          selected,
      }"
      size="large"
      variant="neutral"
      :icon="icon"
      :aria-label="$t(label)"
      @click="$emit('click', name)"
    />
    <CommonUpdateIndicator v-if="!selected && updateIndicator" />
    <CommonLabel
      v-if="badge"
      size="xs"
      class="pointer-events-none absolute -bottom-2 block min-w-4 max-w-10 truncate rounded-full border-2 border-white px-0.5 py-0.5 text-center font-bold text-white ltr:-right-1.5 rtl:-left-1.5 dark:border-gray-500"
      :class="[badgeColor]"
      :aria-label="$t(badge.label)"
      role="status"
    >
      {{ processedBadgeValue }}
    </CommonLabel>
  </div>
</template>
