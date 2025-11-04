<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { toRef } from 'vue'

import { useEscalationState, EscalationState } from '#shared/composables/useEscalationState.ts'
import type { TicketById } from '#shared/entities/ticket/types.ts'

interface Props {
  ticket: TicketById
  hasPopover?: boolean
}

const props = defineProps<Props>()

const escalationState = useEscalationState(toRef(props.ticket, 'escalationAt'))
</script>

<template>
  <CommonBadge
    v-if="ticket?.escalationAt && escalationState !== EscalationState.None"
    :variant="escalationState === EscalationState.Escalated ? 'danger' : 'warning'"
    class="uppercase h-7"
    :class="hasPopover ? 'cursor-pointer' : ''"
    role="alert"
  >
    <CommonIcon name="warning-triangle" class="me-1" size="xs" decorative />
    {{ $t('escalation %s', i18n.relativeDateTime(ticket.escalationAt)) }}
  </CommonBadge>
</template>
