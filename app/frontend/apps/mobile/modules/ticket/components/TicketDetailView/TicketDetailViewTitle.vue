<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonTicketPriorityIndicator from '@shared/components/CommonTicketPriorityIndicator/CommonTicketPriorityIndicator.vue'
import CommonUserAvatar from '@shared/components/CommonUserAvatar/CommonUserAvatar.vue'
import CommonTicketStateIndicator from '@shared/components/CommonTicketStateIndicator/CommonTicketStateIndicator.vue'
import { computed } from 'vue'
import type { TicketById } from '../../types/tickets'

interface Props {
  ticket: TicketById
}

const props = defineProps<Props>()

const customer = computed(() => {
  const { customer } = props.ticket
  if (!customer) return ''
  const { fullname } = customer
  if (fullname === '-') return ''
  return fullname
})
</script>

<template>
  <header
    class="flex border-b-[0.5px] border-white/10 bg-gray-600/90 py-5 px-4"
    data-test-id="title-content"
  >
    <div class="ltr:mr-3 rtl:ml-3">
      <CommonUserAvatar :entity="ticket.customer" />
    </div>
    <div class="overflow-hidden">
      <div class="flex text-sm leading-4 text-gray-100">
        <div
          class="overflow-hidden text-ellipsis whitespace-nowrap"
          :class="{
            'max-w-[80vw]': !ticket.organization,
            'max-w-[40vw]': ticket.organization,
          }"
        >
          {{ customer }}
        </div>
        <template v-if="ticket.organization">
          <div class="px-1">·</div>
          <div
            class="max-w-[40vw] overflow-hidden text-ellipsis whitespace-nowrap"
          >
            {{ ticket.organization.name }}
          </div>
        </template>
      </div>
      <div
        role="heading"
        class="break-words text-xl font-bold leading-7 line-clamp-3"
      >
        {{ ticket.title }}
      </div>
      <div class="mt-2 flex gap-2">
        <CommonTicketStateIndicator
          :status="ticket.state.stateType.name"
          :label="ticket.state.name"
          pill
        />
        <CommonTicketPriorityIndicator :priority="ticket.priority" />
      </div>
    </div>
  </header>
</template>
