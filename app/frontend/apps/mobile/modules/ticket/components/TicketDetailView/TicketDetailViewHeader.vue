<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import type { AvatarUser } from '@shared/components/CommonUserAvatar'
import CommonUserAvatar from '@shared/components/CommonUserAvatar/CommonUserAvatar.vue'
import { useDialog } from '@shared/composables/useDialog'
import CommonLoader from '@mobile/components/CommonLoader/CommonLoader.vue'
import CommonBackButton from '@mobile/components/CommonBackButton/CommonBackButton.vue'

interface Props {
  ticketId: string
  createdAt: string
  loadingTicket?: boolean
  loadingUsers?: boolean
  users: AvatarUser[]
}

defineProps<Props>()

const dialog = useDialog({
  name: 'ticket-dialog',
  component: () => import('./TicketViewersDialog.vue'),
  prefetch: true,
})

const showViewers = () => {
  return dialog.open({ name: dialog.name })
}
</script>

<template>
  <header
    class="grid h-[64px] grid-cols-[70px_auto_70px] border-b-[0.5px] border-white/10 bg-gray-600/90 px-4"
  >
    <CommonBackButton class="justify-self-start" fallback="/" />
    <CommonLoader data-test-id="loader-header" :loading="loadingTicket" center>
      <div
        class="flex flex-1 flex-col items-center justify-center text-center text-sm leading-4"
        data-test-id="header-content"
      >
        <div class="font-bold">{{ ticketId && `#${ticketId}` }}</div>
        <div class="text-gray">
          {{ createdAt && $t('created %s', i18n.relativeDateTime(createdAt)) }}
        </div>
      </div>
    </CommonLoader>
    <CommonLoader :loading="loadingUsers" right>
      <button
        v-if="users.length"
        class="flex cursor-pointer items-center justify-self-end"
        data-test-id="viewers-counter"
        :title="$t('Show ticket viewers')"
        @click="showViewers()"
      >
        <div class="flex">
          <CommonUserAvatar
            class="z-10"
            :entity="users[0]"
            personal
            size="xs"
          />
          <div
            v-if="users.length - 1"
            class="z-0 flex h-6 w-6 -translate-x-2 items-center justify-center rounded-full bg-white/80 text-xs text-black"
            role="img"
            :aria-label="$t('Ticket has %s viewers', users.length)"
          >
            +{{ users.length - 1 }}
          </div>
        </div>
        <CommonIcon name="overflow-button" size="small" />
      </button>
    </CommonLoader>
  </header>
</template>
