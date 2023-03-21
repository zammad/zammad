<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'
import { useReactiveNow } from '@shared/composables/useReactiveNow'
import type { Scalars } from '@shared/graphql/types'

export interface Props {
  escalationAt?: Maybe<Scalars['ISO8601DateTime']>
}

const props = defineProps<Props>()

enum EscalationState {
  Escalated = 'escalated',
  Warning = 'warning',
  None = 'none',
}

const reactiveNow = useReactiveNow()

const escalationState = computed(() => {
  if (!props.escalationAt) return EscalationState.None

  const date = new Date(props.escalationAt)
  if (Number.isNaN(date.getTime())) return EscalationState.None

  const diffSeconds = (reactiveNow.value.getTime() - date.getTime()) / 1000

  // Escalation is in the past.
  if (diffSeconds > -1) return EscalationState.Escalated

  // Escalation is in the future.
  return EscalationState.Warning
})
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
    class="flex select-none items-center rounded bg-gray-100 py-1 text-black ltr:pr-1.5 ltr:pl-1 rtl:pl-1.5 rtl:pr-1"
    role="alert"
  >
    <CommonIcon name="mobile-warning-triangle" size="tiny" decorative />
    <div
      v-if="escalationAt"
      class="text-xs uppercase leading-[14px] ltr:ml-[2px] rtl:mr-[2px]"
    >
      {{ $t('escalation %s', i18n.relativeDateTime(escalationAt)) }}
    </div>
  </div>
</template>
