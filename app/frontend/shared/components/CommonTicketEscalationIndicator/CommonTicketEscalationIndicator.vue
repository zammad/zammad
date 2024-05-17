<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

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
    class="flex select-none items-center rounded bg-gray-100 py-1 text-black ltr:pl-1 ltr:pr-1.5 rtl:pl-1.5 rtl:pr-1"
    role="alert"
  >
    <CommonIcon name="ticket-escalating" size="tiny" decorative />
    <div
      v-if="escalationAt"
      class="text-xs uppercase leading-[14px] ltr:ml-[2px] rtl:mr-[2px]"
    >
      {{ $t('escalation %s', i18n.relativeDateTime(escalationAt)) }}
    </div>
  </div>
</template>
