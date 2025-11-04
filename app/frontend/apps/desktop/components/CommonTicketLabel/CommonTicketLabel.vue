<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import { useTicketNumberAndTitle } from '#shared/entities/ticket/composables/useTicketNumberAndTitle.ts'
import type { TicketById } from '#shared/entities/ticket/types.ts'
import { EnumTicketStateColorCode } from '#shared/graphql/types.ts'

import CommonTicketStateIndicatorIcon from '#desktop/components/CommonTicketStateIndicator/CommonTicketStateIndicatorIcon.vue'

interface Props {
  ticket?: Partial<TicketById> | null
  unauthorized?: boolean
  noLink?: boolean
  noWrap?: boolean
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

const iconSize = computed(() => (props.noWrap ? 'small' : 'tiny'))

const component = computed(() => (props.noLink ? 'div' : 'CommonLink'))

const { getTicketNumberWithTitle } = useTicketNumberAndTitle()
</script>

<template>
  <div v-if="unauthorized" class="flex grow items-center gap-2">
    <CommonIcon class="shrink-0 text-red-500" :size="iconSize" name="x-lg" />
    <CommonLabel class="text-black! dark:text-white!">{{ $t('Access denied') }}</CommonLabel>
  </div>
  <component
    :is="component"
    v-else
    v-tooltip="!noLink ? getTicketNumberWithTitle(ticket?.number, ticket?.title) : undefined"
    class="flex! grow gap-2 rounded-md break-words group-hover/tab:bg-blue-600 hover:no-underline! focus-visible:rounded-md focus-visible:outline-hidden group-hover/tab:dark:bg-blue-900"
    :class="{
      group: !noLink,
      'items-start': !noWrap,
      'items-center': noWrap,
    }"
    :style="{
      wordBreak: !noWrap ? 'normal' : undefined,
      overflowWrap: !noWrap ? 'anywhere' : undefined,
    }"
    :link="!noLink ? `/tickets/${ticket?.internalId}` : undefined"
    :internal="!noLink ? true : undefined"
  >
    <CommonTicketStateIndicatorIcon
      class="ms-0.5 mt-1 shrink-0"
      :class="[classes?.indicator || '', { 'ms-0! mt-0!': noWrap }]"
      :color-code="ticketColorCode"
      :label="ticketState"
      :aria-labelledby="ticketId"
      :icon-size="iconSize"
    />
    <CommonLabel
      :id="ticketId"
      class="mt-0.5 text-blue-800! group-hover:text-blue-850! group-hover:dark:text-blue-600!"
      :class="[classes?.label || '', { 'mt-0! line-clamp-1!': noWrap }]"
    >
      {{ ticket?.title }}
    </CommonLabel>
  </component>
</template>
