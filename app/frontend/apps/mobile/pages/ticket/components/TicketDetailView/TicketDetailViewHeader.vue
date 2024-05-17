<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { toRef } from 'vue'

import CommonUserAvatar from '#shared/components/CommonUserAvatar/CommonUserAvatar.vue'
import type {
  TicketById,
  TicketLiveAppUser,
} from '#shared/entities/ticket/types.ts'
import { useSessionStore } from '#shared/stores/session.ts'

import CommonLoader from '#mobile/components/CommonLoader/CommonLoader.vue'
import LayoutHeader from '#mobile/components/layout/LayoutHeader.vue'
import { useDialog } from '#mobile/composables/useDialog.ts'

interface Props {
  ticket?: TicketById
  liveUserList?: TicketLiveAppUser[]
  loadingTicket?: boolean
  refetchingTicket: boolean
}

const props = defineProps<Props>()
const session = useSessionStore()

const viewersDialog = useDialog({
  name: 'ticket-viewers-dialog',
  component: () => import('./TicketViewersDialog.vue'),
})

const actionsDialog = useDialog({
  name: 'ticket-header-actions-dialog',
  component: () => import('./TicketActionsDialog.vue'),
})

const showViewers = () => {
  return viewersDialog.open({
    name: viewersDialog.name,
    liveUsers: toRef(props, 'liveUserList'),
  })
}

const showActions = () => {
  if (!props.ticket) return

  actionsDialog.open({
    name: actionsDialog.name,
    ticket: toRef(props, 'ticket'),
  })
}
</script>

<template>
  <LayoutHeader
    class="bg-gray-600/90"
    :refetch="refetchingTicket || loadingTicket"
    :back-ignore="[`/tickets/${ticket?.internalId}/information`]"
    back-url="/"
  >
    <div
      class="flex flex-1 flex-col items-center justify-center text-center text-sm leading-4"
      data-test-id="header-content"
    >
      <div class="font-bold">
        {{ ticket && `#${ticket.number}` }}
      </div>
      <div class="text-gray">
        {{
          ticket && $t('created %s', i18n.relativeDateTime(ticket.createdAt))
        }}
      </div>
    </div>

    <template #after>
      <CommonLoader data-test-id="loader-header" :loading="loadingTicket">
        <button
          v-if="liveUserList?.length"
          class="flex ltr:mr-0.5 rtl:ml-0.5"
          data-test-id="viewers-counter"
          type="button"
          :aria-label="$t('Show ticket viewers')"
          @click="showViewers()"
        >
          <CommonUserAvatar
            class="z-10"
            :entity="liveUserList[0].user"
            personal
            size="xs"
          />
          <div
            v-if="liveUserList.length - 1"
            class="z-0 flex h-6 w-6 select-none items-center justify-center rounded-full bg-white/80 text-xs text-black ltr:-translate-x-2 rtl:translate-x-2"
            role="img"
            :aria-label="$t('Ticket has %s viewers', liveUserList.length)"
          >
            +{{ liveUserList.length - 1 }}
          </div>
        </button>
        <button
          v-if="session.hasPermission('ticket.agent')"
          type="button"
          :aria-label="$t('Show ticket actions')"
          @click="showActions()"
        >
          <CommonIcon name="more" size="base" decorative />
        </button>
      </CommonLoader>
    </template>
  </LayoutHeader>
</template>
