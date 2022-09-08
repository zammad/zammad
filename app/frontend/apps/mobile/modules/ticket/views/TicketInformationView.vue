<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import type { ButtonPillOption } from '@mobile/components/CommonButtonPills/types'
import { useHeader } from '@mobile/composables/useHeader'
import { computed, provide } from 'vue'
import CommonButtonPills from '@mobile/components/CommonButtonPills/CommonButtonPills.vue'
import { QueryHandler } from '@shared/server/apollo/handler'
import CommonLoader from '@mobile/components/CommonLoader/CommonLoader.vue'
import { useSessionStore } from '@shared/stores/session'
import { truthy } from '@shared/utils/helpers'
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

const session = useSessionStore()

const types = computed<ButtonPillOption[]>(() =>
  [
    {
      label: __('Ticket'),
      value: 'TicketInformationDetails',
    },
    session.hasPermission(['ticket.agent']) && {
      label: __('Customer'),
      value: 'TicketInformationCustomer',
    },
    ticket.value?.organization && {
      label: __('Organization'),
      value: 'TicketInformationOrganization',
    },
  ].filter(truthy),
)
</script>

<template>
  <div class="p-4">
    <!-- TODO fixed size? "..." for long titles -->
    <h1 class="text-xl font-bold">
      <CommonLoader :loading="loadingTicket">{{ ticket?.title }}</CommonLoader>
    </h1>
  </div>
  <CommonButtonPills
    class="px-4 pb-4"
    no-border
    :options="types"
    :model-value="($route.name as string)"
    @update:model-value="$router.replace({ name: $event as string })"
  />
  <div class="px-4">
    <RouterView />
  </div>
</template>
