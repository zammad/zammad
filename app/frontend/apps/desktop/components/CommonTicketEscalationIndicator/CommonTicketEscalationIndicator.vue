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
  <CommonBadge
    v-if="escalationAt && escalationState !== EscalationState.None"
    :variant="
      escalationState === EscalationState.Escalated ? 'danger' : 'warning'
    "
    class="uppercase"
    role="alert"
  >
    <CommonIcon name="warning-triangle" class="me-1" size="xs" decorative />
    {{ $t('escalation %s', i18n.relativeDateTime(escalationAt)) }}
  </CommonBadge>
</template>
