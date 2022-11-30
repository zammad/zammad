<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

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

defineProps<{
  internalId: string
}>()

const { ticket, ticketQuery, canSubmitForm, canUpdateTicket } =
  useTicketInformation()

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
        type="button"
        :title="$t('Show ticket actions')"
        @click="showActions()"
      >
        <CommonIcon name="mobile-more" size="base" decorative />
      </button>
    </div>
  </header>
  <div class="flex p-4">
    <!-- TODO fixed size? "..." for long titles -->
    <h1 class="flex flex-1 items-center text-xl font-bold">
      <CommonLoader position="left" :loading="loadingTicket">
        {{ ticket?.title }}
      </CommonLoader>
    </h1>
    <button
      v-if="canUpdateTicket"
      class="h-10 w-10 rounded-full bg-yellow p-1 text-black disabled:bg-yellow/50"
      form="form-ticket-edit"
      :disabled="!canSubmitForm"
      :title="$t('Save ticket')"
    >
      <CommonIcon name="mobile-arrow-up" decorative />
    </button>
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
