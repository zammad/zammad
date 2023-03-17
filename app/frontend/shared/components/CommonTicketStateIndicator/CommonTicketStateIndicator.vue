<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'
import { EnumTicketStateColorCode } from '@shared/graphql/types'

export interface Props {
  colorCode: EnumTicketStateColorCode
  label: string
  pill?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  pill: false,
})

const textClass = computed(() => {
  switch (props.colorCode) {
    case EnumTicketStateColorCode.Closed:
      return 'text-green'
    case EnumTicketStateColorCode.Pending:
      return 'text-gray'
    case EnumTicketStateColorCode.Escalating:
      return 'text-red-bright'
    case EnumTicketStateColorCode.Open:
    default:
      return 'text-yellow'
  }
})

const backgroundClass = computed(() => {
  if (!props.pill) return

  switch (props.colorCode) {
    case EnumTicketStateColorCode.Closed:
      return 'bg-green-highlight'
    case EnumTicketStateColorCode.Pending:
      return 'bg-gray-highlight'
    case EnumTicketStateColorCode.Escalating:
      return 'bg-red-dark'
    case EnumTicketStateColorCode.Open:
    default:
      return 'bg-yellow-highlight'
  }
})
</script>

<template>
  <div
    :class="[
      textClass,
      backgroundClass,
      {
        'rounded py-1 pr-1.5 pl-1': pill,
      },
    ]"
    class="flex select-none items-center"
    role="group"
  >
    <CommonIcon
      :size="pill ? 'tiny' : 'base'"
      :label="$t('(state: %s)', $t(label))"
      name="mobile-check-circle-no"
    />
    <div
      v-if="pill"
      class="ml-[2px] text-xs uppercase leading-[14px]"
      aria-hidden="true"
    >
      {{ label }}
    </div>
  </div>
</template>
