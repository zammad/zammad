<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import type { ButtonPillOption } from '@mobile/components/CommonButtonPills/types'
import { useHeader } from '@mobile/composables/useHeader'
import { computed, provide } from 'vue'
import CommonButtonPills from '@mobile/components/CommonButtonPills/CommonButtonPills.vue'
import { QueryHandler } from '@shared/server/apollo/handler'
import CommonLoader from '@mobile/components/CommonLoader/CommonLoader.vue'
import { useTicketQuery } from '../graphql/queries/ticket.api'

const props = defineProps<{
  internalId: string
}>()

// TODO use another query? we only need title and subscribers here
// ticket form will be loaded with formId

const ticketQuery = new QueryHandler(
  useTicketQuery({
    ticketInternalId: Number(props.internalId),
  }),
)

const ticketResult = ticketQuery.result()
const ticket = computed(() => ticketResult.value?.ticket)

const loadingTicket = ticketQuery.loading()

provide('ticket', ticket)

useHeader({
  backTitle: computed(() => `#${props.internalId}`),
  backUrl: computed(() => `/tickets/${props.internalId}`),
  title: __('Ticket information'),
})

const types: ButtonPillOption[] = [
  {
    label: __('Ticket'),
    value: 'TicketInformationDetails',
  },
  {
    label: __('Customer'),
    value: 'TicketInformationCustomer',
  },
  {
    label: __('Organization'),
    value: 'TicketInformationOrganization',
    permissions: ['ticket.agent'],
  },
]
</script>

<template>
  <div class="p-4">
    <!-- TODO fixed size? "..." for long titles -->
    <h1 class="text-xl font-bold">
      <CommonLoader :loading="loadingTicket">{{ ticket?.title }}</CommonLoader>
    </h1>
  </div>
  <CommonButtonPills
    no-border
    :options="types"
    :model-value="($route.name as string)"
    @update:model-value="$router.replace({ name: $event as string })"
  />
  <div class="px-4">
    <RouterView />
  </div>
</template>
