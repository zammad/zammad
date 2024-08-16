<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import type { Sizes } from '#shared/components/CommonIcon/types.ts'
import { EnumTicketStateColorCode } from '#shared/graphql/types.ts'

export interface Props {
  colorCode: EnumTicketStateColorCode
  label: string
  iconSize?: Sizes
}

const props = withDefaults(defineProps<Props>(), {
  iconSize: 'xs',
})

const iconName = computed(() => {
  switch (props.colorCode) {
    case EnumTicketStateColorCode.Closed:
      return 'check-circle-outline'
    case EnumTicketStateColorCode.Pending:
      return 'check-circle-outline-dashed'
    case EnumTicketStateColorCode.Escalating:
      return 'warning-triangle'
    case EnumTicketStateColorCode.Open:
    default:
      return 'check-circle-no'
  }
})

const iconColor = computed(() => {
  switch (props.colorCode) {
    case EnumTicketStateColorCode.Closed:
      return 'text-green-400'
    case EnumTicketStateColorCode.Pending:
      return 'text-stone-400'
    case EnumTicketStateColorCode.Escalating:
      return 'text-red-300'
    case EnumTicketStateColorCode.Open:
    default:
      return 'text-yellow-500'
  }
})

const isEscalating = computed(
  () => props.colorCode === EnumTicketStateColorCode.Escalating,
  // assertive is used for screen readers to announce the change immediately only for escalating state
  // polite is used for screen readers to announce the change after the current announcement
)
</script>

<template>
  <CommonIcon
    role="status"
    :aria-live="isEscalating ? 'assertive' : 'polite'"
    :aria-roledescription="$t('(ticket status: %s)', $t(colorCode))"
    :class="iconColor"
    :name="iconName"
    :size="iconSize"
  />
</template>

<style scoped>
.router-link-active > * > .icon {
  @apply text-white;
}
</style>
