<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { toRef } from 'vue'

import {
  useEscalationState,
  EscalationState,
} from '#shared/composables/useEscalationState.ts'
import type { Scalars } from '#shared/graphql/types.ts'

import CommonSectionMenuItem from '#mobile/components/CommonSectionMenu/CommonSectionMenuItem.vue'

const props = defineProps<{
  label: string
  escalationAt?: Maybe<Scalars['ISO8601DateTime']['output']>
}>()

const escalationState = useEscalationState(toRef(() => props.escalationAt))
</script>

<template>
  <CommonSectionMenuItem
    v-if="escalationAt && escalationState !== EscalationState.None"
    :class="{
      'text-red-bright bg-red-highlight':
        escalationState === EscalationState.Escalated,
      'text-yellow bg-yellow-highlight':
        escalationState === EscalationState.Warning,
    }"
    :label="label"
  >
    {{ i18n.relativeDateTime(escalationAt) }}
  </CommonSectionMenuItem>
</template>
