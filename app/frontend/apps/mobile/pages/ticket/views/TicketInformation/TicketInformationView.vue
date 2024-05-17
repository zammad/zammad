<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'

import { useStickyHeader } from '#shared/composables/useStickyHeader.ts'
import { useSessionStore } from '#shared/stores/session.ts'

import CommonButtonGroup from '#mobile/components/CommonButtonGroup/CommonButtonGroup.vue'
import type { CommonButtonOption } from '#mobile/components/CommonButtonGroup/types.ts'
import CommonLoader from '#mobile/components/CommonLoader/CommonLoader.vue'
import LayoutHeader from '#mobile/components/layout/LayoutHeader.vue'
import { useDialog } from '#mobile/composables/useDialog.ts'

import { useTicketInformation } from '../../composable/useTicketInformation.ts'

import { ticketInformationPlugins } from './plugins/index.ts'

defineProps<{
  internalId: string
}>()

const { ticket, ticketQuery, refetchingStatus } = useTicketInformation()

const loadingTicket = ticketQuery.loading()

const { hasPermission } = useSessionStore()

const actionsDialog = useDialog({
  name: 'ticket-actions-dialog',
  component: () =>
    import('../../components/TicketDetailView/TicketActionsDialog.vue'),
})

const showActions = () => {
  return actionsDialog.open({
    name: actionsDialog.name,
    ticket,
  })
}

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

const { stickyStyles, headerElement } = useStickyHeader()

const route = useRoute()
const router = useRouter()
</script>

<template>
  <LayoutHeader
    ref="headerElement"
    :refetch="refetchingStatus"
    :back-title="`#${internalId}`"
    :title="$t('Ticket information')"
    :back-url="`/tickets/${internalId}`"
    :style="stickyStyles.header"
  >
    <template #after>
      <button
        v-if="hasPermission('ticket.agent')"
        type="button"
        :aria-label="$t('Show ticket actions')"
        @click="showActions()"
      >
        <CommonIcon name="more" size="base" decorative />
      </button>
    </template>
  </LayoutHeader>
  <div class="flex p-4" :style="stickyStyles.body">
    <h1
      class="line-clamp-3 flex flex-1 items-center break-words text-xl font-bold leading-7"
    >
      <CommonLoader position="left" :loading="loadingTicket">
        {{ ticket?.title }}
      </CommonLoader>
    </h1>
  </div>
  <CommonButtonGroup
    v-if="types.length > 1"
    class="px-4 pb-4"
    as="tabs"
    controls="route-ticket-information-tabpanel"
    :options="types"
    :model-value="route.name as string"
    @update:model-value="router.replace({ name: $event as string })"
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
