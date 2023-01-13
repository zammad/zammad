<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'
import type { CommonButtonOption } from '@mobile/components/CommonButtonGroup/types'
import CommonButtonGroup from '@mobile/components/CommonButtonGroup/CommonButtonGroup.vue'
import CommonLoader from '@mobile/components/CommonLoader/CommonLoader.vue'
import { useSessionStore } from '@shared/stores/session'
import CommonBackButton from '@mobile/components/CommonBackButton/CommonBackButton.vue'
import { useDialog } from '@shared/composables/useDialog'
import { ticketInformationPlugins } from './plugins'
import { useTicketInformation } from '../../composable/useTicketInformation'
import TicketDetailViewUpdateButton from '../../components/TicketDetailView/TicketDetailViewUpdateButton.vue'

defineProps<{
  internalId: string
}>()

const {
  ticket,
  ticketQuery,
  newTicketArticlePresent,
  isTicketFormGroupValid,
  isArticleFormGroupValid,
  showArticleReplyDialog,
} = useTicketInformation()

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

const submitForm = () => {
  if (
    isTicketFormGroupValid.value &&
    newTicketArticlePresent.value &&
    !isArticleFormGroupValid.value
  ) {
    showArticleReplyDialog()
  }
}
</script>

<template>
  <header
    class="grid h-[64px] grid-cols-[75px_auto_75px] border-b-[0.5px] border-white/10 px-4"
  >
    <CommonBackButton
      class="justify-self-start"
      :label="`#${internalId}`"
      :fallback="`/tickets/${internalId}`"
    />
    <div
      class="flex flex-1 items-center justify-center text-center text-lg font-bold"
    >
      {{ $t('Ticket information') }}
    </div>
    <div class="flex items-center justify-end">
      <button
        v-if="hasPermission('ticket.agent')"
        type="button"
        :title="$t('Show ticket actions')"
        @click="showActions()"
      >
        <CommonIcon name="mobile-more" size="base" decorative />
      </button>
    </div>
  </header>
  <div class="flex p-4">
    <h1
      class="flex flex-1 items-center break-words text-xl font-bold leading-7 line-clamp-3"
    >
      <CommonLoader position="left" :loading="loadingTicket">
        {{ ticket?.title }}
      </CommonLoader>
    </h1>
    <TicketDetailViewUpdateButton
      class="rtl-mr-3 ltr:ml-3"
      @click="submitForm"
    />
  </div>
  <CommonButtonGroup
    v-if="types.length > 1"
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
