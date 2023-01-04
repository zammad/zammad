<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, toRef } from 'vue'
import CommonTicketStateIndicator from '@shared/components/CommonTicketStateIndicator/CommonTicketStateIndicator.vue'
import CommonTicketPriorityIndicator from '@shared/components/CommonTicketPriorityIndicator/CommonTicketPriorityIndicator.vue'
import { useEditedBy } from '@mobile/composables/useEditedBy'
import { type TicketItemData } from './types'

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
      <!-- TODO label? -->
      <CommonTicketStateIndicator :status="entity.state.name" label="" />
    </div>
    <div
      class="flex flex-1 items-center gap-1 overflow-hidden border-b border-white/10 py-3 text-gray-100 ltr:pr-2 rtl:pl-2"
    >
      <div class="flex-1 overflow-hidden text-ellipsis whitespace-nowrap">
        <span>
          #{{ entity.number }}
          <template v-if="customer">
            ·
            {{ customer }}
          </template>
        </span>
        <span
          class="mb-1 whitespace-normal text-lg font-bold leading-5 line-clamp-3"
        >
          <slot>
            {{ entity.title }}
          </slot>
        </span>
        <div
          v-if="stringUpdated"
          data-test-id="stringUpdated"
          class="overflow-hidden text-ellipsis text-gray"
        >
          {{ stringUpdated }}
        </div>
      </div>
      <CommonTicketPriorityIndicator :priority="entity.priority" />
    </div>
  </div>
</template>
