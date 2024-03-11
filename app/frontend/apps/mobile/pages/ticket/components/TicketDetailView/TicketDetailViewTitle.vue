<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, toRef } from 'vue'
import CommonTicketPriorityIndicator from '#shared/components/CommonTicketPriorityIndicator/CommonTicketPriorityIndicator.vue'
import CommonUserAvatar from '#shared/components/CommonUserAvatar/CommonUserAvatar.vue'
import CommonOrganizationAvatar from '#shared/components/CommonOrganizationAvatar/CommonOrganizationAvatar.vue'
import CommonTicketEscalationIndicator from '#shared/components/CommonTicketEscalationIndicator/CommonTicketEscalationIndicator.vue'
import CommonTicketStateIndicator from '#shared/components/CommonTicketStateIndicator/CommonTicketStateIndicator.vue'
import type { TicketById } from '#shared/entities/ticket/types.ts'
import { useLocaleStore } from '#shared/stores/locale.ts'
import { useTicketView } from '#shared/entities/ticket/composables/useTicketView.ts'
import { useTicketChannel } from '#shared/entities/ticket/composables/useTicketChannel.ts'

interface Props {
  ticket: TicketById
}

const props = defineProps<Props>()

const ticketReactive = toRef(props, 'ticket')

// TODO: Maybe in the future we can hide additional information (e.g. the priority) directly with the graphql query for
//  the ticket details (similar to the ticket list).
const { isTicketAgent, isTicketEditable } = useTicketView(ticketReactive)

const { hasChannelAlert, channelAlert } = useTicketChannel(ticketReactive)

const locale = useLocaleStore()

const customer = computed(() => {
  const { customer } = props.ticket
  if (!customer) return ''
  const { fullname } = customer
  if (fullname === '-') return ''
  return fullname
})
</script>

<template>
  <div data-test-id="ticket-title" class="relative">
    <div class="border-b-[0.5px] border-white/10 bg-gray-600/90">
      <CommonLink
        class="flex px-4 py-5"
        data-test-id="title-content"
        :link="`/tickets/${ticket.internalId}/information`"
      >
        <div class="flex ltr:mr-3 rtl:ml-3">
          <CommonUserAvatar class="z-10" :entity="ticket.customer" />
          <CommonOrganizationAvatar
            v-if="ticket.organization"
            class="z-0 ltr:-translate-x-1 rtl:translate-x-1"
            :entity="ticket.organization"
          />
        </div>
        <div
          class="overflow-hidden ltr:mr-1 rtl:ml-1"
          :class="{ 'rtl:-mr-1 ltr:-ml-1': ticket.organization }"
        >
          <div class="flex text-sm leading-4 text-gray-100">
            <div
              class="truncate"
              :class="{
                'max-w-[80vw]': !ticket.organization,
                'max-w-[40vw]': ticket.organization,
              }"
            >
              {{ customer }}
            </div>
            <template v-if="ticket.organization">
              <div class="px-1">·</div>
              <div class="max-w-[40vw] truncate">
                {{ ticket.organization.name }}
              </div>
            </template>
          </div>
          <h1 class="line-clamp-3 break-words text-xl font-bold leading-7">
            {{ ticket.title }}
          </h1>
          <div class="mt-2 flex flex-wrap gap-2">
            <CommonTicketEscalationIndicator
              v-if="isTicketAgent && ticket.escalationAt"
              :escalation-at="ticket.escalationAt"
            />
            <CommonTicketStateIndicator
              :color-code="ticket.stateColorCode"
              :label="ticket.state.name"
              pill
            />
            <CommonTicketPriorityIndicator
              v-if="isTicketAgent"
              :priority="ticket.priority"
            />
          </div>
        </div>
        <CommonIcon
          :name="`chevron-${locale.localeData?.dir === 'rtl' ? 'left' : 'right'}`"
          size="base"
          class="shrink-0 self-center ltr:-mr-2 ltr:ml-auto rtl:-ml-2 rtl:mr-auto"
          decorative
        />
      </CommonLink>
    </div>
    <CommonAlert
      v-if="isTicketAgent && isTicketEditable && hasChannelAlert"
      class="rounded-b-lg"
      :variant="channelAlert?.variant"
    >
      {{ $t(channelAlert?.text, channelAlert?.textPlaceholder) }}
    </CommonAlert>
  </div>
</template>
