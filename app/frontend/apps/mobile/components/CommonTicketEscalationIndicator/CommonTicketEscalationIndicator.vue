<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { toRef } from 'vue'

import {
  useEscalationState,
  EscalationState,
} from '#shared/composables/useEscalationState.ts'
import type { Scalars } from '#shared/graphql/types.ts'

export interface Props {
  escalationAt?: Maybe<Scalars['ISO8601DateTime']['output']>
}

const props = defineProps<Props>()

const escalationState = useEscalationState(toRef(() => props.escalationAt))
</script>

<template>
  <div
    v-if="escalationState !== EscalationState.None"
    :class="{
      'bg-red-dark text-red-bright':
        escalationState === EscalationState.Escalated,
      'bg-yellow-highlight text-yellow':
        escalationState === EscalationState.Warning,
    }"
    class="flex items-center rounded bg-gray-100 py-1 text-black select-none ltr:pr-1.5 ltr:pl-1 rtl:pr-1 rtl:pl-1.5"
    role="alert"
  >
    <CommonIcon name="ticket-escalating" size="tiny" decorative />
    <div
      v-if="escalationAt"
      class="text-xs leading-[14px] uppercase ltr:ml-[2px] rtl:mr-[2px]"
    >
      {{ $t('escalation %s', i18n.relativeDateTime(escalationAt)) }}
    </div>
  </div>
</template>
