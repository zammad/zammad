<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, toRef } from 'vue'

import CommonTicketPriorityIndicator from '#mobile/components/CommonTicketPriorityIndicator/CommonTicketPriorityIndicator.vue'
import CommonTicketStateIndicator from '#mobile/components/CommonTicketStateIndicator/CommonTicketStateIndicator.vue'
import { useEditedBy } from '#mobile/composables/useEditedBy.ts'

import { type TicketItemData } from './types.ts'

export interface Props {
  entity: TicketItemData
}

const props = defineProps<Props>()

const { stringUpdated } = useEditedBy(toRef(props, 'entity'))

const customer = computed(() => {
  const { customer } = props.entity
  if (!customer) return ''
  const { fullname } = customer
  if (fullname === '-') return ''
  return fullname
})
</script>

<template>
  <div class="flex cursor-pointer ltr:pr-3 rtl:pl-3">
    <div class="flex w-14 items-center justify-center">
      <CommonIcon
        v-if="entity.aiAgentRunning"
        role="status"
        :aria-label="$t('Currently processing this ticket…')"
        size="small"
        name="check-circle-no-ai"
      />
      <CommonTicketStateIndicator
        v-else
        :color-code="entity.stateColorCode"
        :label="entity.state.name"
      />
    </div>
    <div
      class="flex flex-1 items-center gap-1 overflow-hidden border-b border-white/10 py-3 text-gray-100 ltr:pr-2 rtl:pl-2"
    >
      <div class="flex-1 truncate">
        <span>
          #{{ entity.number }}
          <template v-if="customer">
            ·
            {{ customer }}
          </template>
        </span>
        <span class="mb-1 line-clamp-3 text-lg leading-5 font-bold whitespace-normal">
          <slot>
            {{ entity.title }}
          </slot>
        </span>
        <div v-if="stringUpdated" data-test-id="stringUpdated" class="text-gray truncate">
          {{ stringUpdated }}
        </div>
      </div>
      <CommonTicketPriorityIndicator :priority="entity.priority" />
    </div>
  </div>
</template>
