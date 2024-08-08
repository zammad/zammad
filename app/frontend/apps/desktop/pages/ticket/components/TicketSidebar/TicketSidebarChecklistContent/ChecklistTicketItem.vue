<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, toRef } from 'vue'

import {
  type ChecklistItem as ChecklistItemType,
  EnumTicketStateColorCode,
} from '#shared/graphql/types.ts'

import CommonTicketStateIndicatorIcon from '#desktop/components/CommonTicketStateIndicatorIcon/CommonTicketStateIndicatorIcon.vue'
import { useTicketNumber } from '#desktop/pages/ticket/composables/useTicketNumber.ts'

interface Props {
  item: ChecklistItemType & {
    ticket: {
      link: string
      title: string
      colorCode: EnumTicketStateColorCode
      state: {
        name: string
      }
    }
  }
}

const props = defineProps<Props>()

const { ticketNumberWithTicketHook } = useTicketNumber(
  // eslint-disable-next-line @typescript-eslint/ban-ts-comment
  // @ts-expect-error
  toRef(props.item, 'ticket'),
)

const tooltip = computed(
  () => `${ticketNumberWithTicketHook.value} - ${props.item.ticket.title}`,
)
</script>

<template>
  <CommonLink
    v-tooltip="tooltip"
    class="flex grow gap-2 rounded-md px-2 py-3 hover:no-underline focus-visible:rounded-md focus-visible:outline-none group-hover/tab:bg-blue-600 group-hover/tab:dark:bg-blue-900"
    :link="item.ticket.link"
    internal
  >
    <CommonTicketStateIndicatorIcon
      class="group-focus-visible/link:text-white"
      :color-code="item.ticket.colorCode"
      :label="item.ticket.state.name"
      icon-size="small"
    />
    <CommonLabel
      class="-:text-gray-300 -:dark:text-neutral-400 block truncate group-focus-visible/link:text-white group-hover/tab:dark:text-white"
    >
      {{ item.ticket.title }}
    </CommonLabel>
  </CommonLink>
</template>
