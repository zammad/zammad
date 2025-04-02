<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import type { TicketById } from '#shared/entities/ticket/types.ts'
import { EnumTicketStateColorCode } from '#shared/graphql/types.ts'

import CommonTicketStateIndicatorIcon from '#desktop/components/CommonTicketStateIndicator/CommonTicketStateIndicatorIcon.vue'

interface Props {
  ticket?: Partial<TicketById> | null
  unauthorized?: boolean
  classes?: {
    indicator?: string
    label?: string
  }
}

const props = defineProps<Props>()

const ticketId = computed(() => `ticket-${props.ticket?.internalId}`)

const ticketState = computed(() => {
  return props.ticket?.state?.name || ''
})

const ticketColorCode = computed(() => {
  return props.ticket?.stateColorCode || EnumTicketStateColorCode.Open
})
</script>

<template>
  <div v-if="unauthorized" class="flex grow items-center gap-2">
    <CommonIcon class="shrink-0 text-red-500" size="tiny" name="x-lg" />
    <CommonLabel class="text-black dark:text-white">{{
      $t('Access denied')
    }}</CommonLabel>
  </div>
  <CommonLink
    v-else
    class="flex! grow items-start gap-2 rounded-md break-words group-hover/tab:bg-blue-600 hover:no-underline! focus-visible:rounded-md focus-visible:outline-hidden group-hover/tab:dark:bg-blue-900"
    style="word-break: normal; overflow-wrap: anywhere"
    :link="`/tickets/${ticket?.internalId}`"
    internal
  >
    <CommonTicketStateIndicatorIcon
      class="ms-0.5 mt-1 shrink-0"
      :class="classes?.indicator || ''"
      :color-code="ticketColorCode"
      :label="ticketState"
      :aria-labelledby="ticketId"
      icon-size="tiny"
    />
    <CommonLabel
      :id="ticketId"
      class="mt-0.5 text-blue-800"
      :class="classes?.label"
    >
      {{ ticket?.title }}
    </CommonLabel>
  </CommonLink>
</template>
