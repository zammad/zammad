<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import type { TicketById } from '#shared/entities/ticket/types.ts'
import type { Ticket } from '#shared/graphql/types.ts'
import { useSessionStore } from '#shared/stores/session.ts'

import { type Props as CommonPopoverProps } from '#desktop//components/CommonPopover/CommonPopover.vue'
import CommonPopoverWithTrigger from '#desktop/components/CommonPopover/CommonPopoverWithTrigger.vue'
import CommonTicketLabel from '#desktop/components/CommonTicketLabel/CommonTicketLabel.vue'

import TicketPopover from './TicketPopoverWithTrigger/TicketPopover.vue'

export interface Props {
  ticket: Partial<Ticket | TicketById>
  popoverConfig?: Omit<CommonPopoverProps, 'owner'>
  triggerClass?: string
  noLink?: boolean
  noFocusStyling?: boolean
  noHoverStyling?: boolean
  zIndex?: string
}

defineProps<Props>()

defineOptions({
  inheritAttrs: false,
})

defineSlots<{
  default(props: {
    isOpen?: boolean | undefined
    popoverId?: string
    hasOpenViaLongClick?: boolean
  }): never
}>()

const session = useSessionStore()

const isAgent = computed(() => session.hasPermission('ticket.agent'))
</script>

<template>
  <CommonPopoverWithTrigger
    v-if="isAgent"
    :class="[
      !$slots?.default?.() ? 'rounded-full! focus-visible:outline-2!' : '',
      triggerClass ?? '',
    ]"
    :no-hover-styling="noHoverStyling"
    :no-focus-styling="noFocusStyling"
    :z-index="zIndex"
    :trigger-link="!noLink ? `/tickets/${ticket.internalId}` : undefined"
    :trigger-link-active-class="
      !$slots?.default?.()
        ? 'outline-2! outline-offset-1! outline-blue-800! hover:outline-blue-800!'
        : ''
    "
    v-bind="{ ...popoverConfig, ...$attrs }"
  >
    <template #popover-content="{ popoverId, hasOpenedViaLongClick }">
      <TicketPopover
        :id="popoverId"
        :ticket="ticket"
        :has-open-via-long-click="hasOpenedViaLongClick"
      />
    </template>

    <template #default="slotProps">
      <slot v-bind="slotProps">
        <CommonTicketLabel class="h-9" :ticket="ticket" no-link no-wrap />
      </slot>
    </template>
  </CommonPopoverWithTrigger>
  <CommonTicketLabel v-else class="h-9" :ticket="ticket" no-wrap />
</template>
