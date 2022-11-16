<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useHeader } from '@mobile/composables/useHeader'
import { computed, provide } from 'vue'
import type { CommonButtonOption } from '@mobile/components/CommonButtonGroup/types'
import CommonButtonGroup from '@mobile/components/CommonButtonGroup/CommonButtonGroup.vue'
import { QueryHandler } from '@shared/server/apollo/handler'
import CommonLoader from '@mobile/components/CommonLoader/CommonLoader.vue'
import { useSessionStore } from '@shared/stores/session'
import { useTicketQuery } from '../../graphql/queries/ticket.api'
import { ticketInformationPlugins } from './plugins'
import { TICKET_INFORMATION_SYMBOL } from './composable/useTicketInformation'

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

provide(TICKET_INFORMATION_SYMBOL, ticket)

useHeader({
  backTitle: computed(() => `#${props.internalId}`),
  backUrl: computed(() => `/tickets/${props.internalId}`),
  title: __('Ticket information'),
})

const { hasPermission } = useSessionStore()

const types = computed<CommonButtonOption[]>(() => {
  return ticketInformationPlugins
    .filter((plugin) => {
      const permissions = plugin.route.meta?.requiredPermission
      if (permissions && !hasPermission(permissions)) {
        return false
      }
      return !plugin.condition || plugin.condition(ticket.value)
    })
    .map((plugins) => {
      return {
        label: plugins.label,
        value: plugins.route.name,
      }
    })
})
</script>

<template>
  <div class="p-4">
    <!-- TODO fixed size? "..." for long titles -->
    <h1 class="text-xl font-bold">
      <CommonLoader position="left" :loading="loadingTicket">
        {{ ticket?.title }}
      </CommonLoader>
    </h1>
  </div>
  <CommonButtonGroup
    class="px-4 pb-4"
    as="tabs"
    controls="route-ticket-information-tabpanel"
    :options="types"
    :model-value="($route.name as string)"
    @update:model-value="$router.replace({ name: $event as string })"
  />
  <div
    id="route-ticket-information-tabpanel"
    role="tabpanel"
    aria-live="polite"
    class="px-4"
  >
    <RouterView />
  </div>
</template>
