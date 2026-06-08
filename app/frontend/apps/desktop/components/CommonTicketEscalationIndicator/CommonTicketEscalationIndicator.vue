<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import type { TicketById } from '#shared/entities/ticket/types.ts'

import CommonPopoverWithTrigger from '#desktop/components/CommonPopover/CommonPopoverWithTrigger.vue'

import CommonTicketEscalationIndicatorBadge from './CommonTicketEscalationIndicatorBadge.vue'
import CommonTicketEscalationIndicatorItem from './CommonTicketEscalationIndicatorItem.vue'

interface Props {
  ticket: TicketById
  hasPopover?: boolean
}

defineProps<Props>()
</script>

<template>
  <CommonPopoverWithTrigger
    v-if="hasPopover"
    class="rounded-md outline-offset-1 focus-visible:outline-2"
    placement="arrowStart"
    orientation="bottom"
    trigger-link-active-class="outline-blue-800! outline-2!"
    :aria-label="$t('Show ticket escalation information')"
  >
    <template #popover-content>
      <div class="p-3">
        <CommonLabel size="large" class="pb-3">
          {{ $t('Escalation times') }}
        </CommonLabel>

        <div class="flex flex-col gap-2.5">
          <CommonTicketEscalationIndicatorItem
            :label="$t('First response time')"
            :escalation-time="ticket?.firstResponseEscalationAt"
          />
          <CommonTicketEscalationIndicatorItem
            :label="$t('Update time')"
            :escalation-time="ticket?.updateEscalationAt"
          />
          <CommonTicketEscalationIndicatorItem
            :label="$t('Solution time')"
            :escalation-time="ticket?.closeEscalationAt"
          />
        </div>
      </div>
    </template>

    <template #default="slotProps">
      <slot v-bind="slotProps">
        <CommonTicketEscalationIndicatorBadge :ticket="ticket" has-popover />
      </slot>
    </template>
  </CommonPopoverWithTrigger>
  <CommonTicketEscalationIndicatorBadge v-else :ticket="ticket" />
</template>
