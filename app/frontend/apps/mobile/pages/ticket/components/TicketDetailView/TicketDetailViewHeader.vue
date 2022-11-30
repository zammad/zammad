<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import type { AvatarUser } from '@shared/components/CommonUserAvatar'
import CommonUserAvatar from '@shared/components/CommonUserAvatar/CommonUserAvatar.vue'
import { useDialog } from '@shared/composables/useDialog'
import CommonLoader from '@mobile/components/CommonLoader/CommonLoader.vue'
import CommonBackButton from '@mobile/components/CommonBackButton/CommonBackButton.vue'
import type { TicketById } from '../../types/tickets'

interface Props {
  ticket?: TicketById
  loadingTicket?: boolean
  loadingUsers?: boolean
  users: AvatarUser[]
}

const props = defineProps<Props>()

const viewersDialog = useDialog({
  name: 'ticket-viewers-dialog',
  component: () => import('./TicketViewersDialog.vue'),
})

const actionsDialog = useDialog({
  name: 'ticket-header-actions-dialog',
  component: () => import('./TicketActionsDialog.vue'),
})

const showViewers = () => {
  return viewersDialog.open({ name: viewersDialog.name })
}

const showActions = () => {
  if (!props.ticket) return

  actionsDialog.open({
    name: actionsDialog.name,
    ticket: props.ticket,
  })
}
</script>

<template>
  <header
    class="grid h-[64px] grid-cols-[75px_auto_75px] border-b-[0.5px] border-white/10 bg-gray-600/90 px-4"
  >
    <CommonBackButton class="justify-self-start" fallback="/" />
    <CommonLoader data-test-id="loader-header" :loading="loadingTicket">
      <div
        class="flex flex-1 flex-col items-center justify-center text-center text-sm leading-4"
        data-test-id="header-content"
      >
        <div class="font-bold">{{ ticket && `#${ticket.number}` }}</div>
        <div class="text-gray">
          {{
            ticket && $t('created %s', i18n.relativeDateTime(ticket.createdAt))
          }}
        </div>
      </div>
    </CommonLoader>
    <CommonLoader :loading="loadingUsers" position="right">
      <div class="flex items-center justify-self-end">
        <button
          v-if="users.length"
          class="flex"
          data-test-id="viewers-counter"
          :title="$t('Show ticket viewers')"
          @click="showViewers()"
        >
          <CommonUserAvatar
            class="z-10"
            :entity="users[0]"
            personal
            size="xs"
          />
          <div
            v-if="users.length - 1"
            class="z-0 flex h-6 w-6 -translate-x-2 select-none items-center justify-center rounded-full bg-white/80 text-xs text-black"
            role="img"
            :aria-label="$t('Ticket has %s viewers', users.length)"
          >
            +{{ users.length - 1 }}
          </div>
        </button>
        <button
          type="button"
          :title="$t('Show ticket actions')"
          @click="showActions()"
        >
          <CommonIcon name="mobile-more" size="base" decorative />
        </button>
      </div>
    </CommonLoader>
  </header>
</template>
