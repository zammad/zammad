<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { toRef, computed } from 'vue'

import { useEscalationState, EscalationState } from '#shared/composables/useEscalationState.ts'
import type { Scalars } from '#shared/graphql/types.ts'
import getUuid from '#shared/utils/getUuid.ts'

export interface Props {
  label: string
  escalationTime?: Maybe<Scalars['ISO8601DateTime']['output']>
}

const props = defineProps<Props>()

const escalationState = useEscalationState(toRef(props, 'escalationTime'))
const labelId = getUuid()
const colorClasses = computed(() => {
  switch (escalationState.value) {
    case EscalationState.Escalated:
      return 'text-red-500'
    case EscalationState.Warning:
      return 'text-yellow-600'
    default:
      return null
  }
})
</script>

<template>
  <div
    v-if="escalationTime && escalationState != EscalationState.None"
    class="flex flex-col"
    :aria-labelledby="labelId"
  >
    <CommonLabel :id="labelId" size="small" class="text-stone-200 dark:text-neutral-500">
      {{ $t(label) }}
    </CommonLabel>

    <CommonLabel size="medium">
      <CommonDateTime :date-time="escalationTime" :class="colorClasses" />
    </CommonLabel>
  </div>
</template>
