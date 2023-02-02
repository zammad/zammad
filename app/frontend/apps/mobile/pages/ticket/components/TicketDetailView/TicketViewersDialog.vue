<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'
import { useReactiveNow } from '@shared/composables/useReactiveNow'
import type { TicketLiveAppUser } from '@shared/entities/ticket/types'
import CommonDialog from '@mobile/components/CommonDialog/CommonDialog.vue'
import CommonSectionMenu from '@mobile/components/CommonSectionMenu/CommonSectionMenu.vue'
import TicketViewerItem from './TicketViewerItem.vue'

interface Props {
  name: string
  liveUsers: TicketLiveAppUser[]
}

const props = defineProps<Props>()

// Default idle time from 5 minutes.
const IDLE_TIME_MS = 5 * 60 * 1000

const reactiveNow = useReactiveNow()

// TODO: We should move this in a shared composable, for usage in the desktop app.
const userViewingTicket = computed(() => {
  const viewingUsers: TicketLiveAppUser[] = []
  const idleUsers: TicketLiveAppUser[] = []

  props.liveUsers.forEach((liveUser) => {
    if (
      new Date(liveUser.lastInteraction).getTime() + IDLE_TIME_MS <
      reactiveNow.value.getTime()
    ) {
      idleUsers.push(liveUser)
    } else {
      viewingUsers.push(liveUser)
    }
  })

  return {
    viewingUsers,
    idleUsers,
  }
})
</script>

<template>
  <CommonDialog
    :name="name"
    :label="__('Ticket viewers')"
    class="w-full p-4 text-sm"
  >
    <CommonSectionMenu
      v-if="userViewingTicket.viewingUsers.length > 0"
      class="!py-4"
      :header-label="__('Viewing ticket')"
    >
      <TicketViewerItem
        v-for="(viewingUser, index) in userViewingTicket.viewingUsers"
        :key="`${index}-${viewingUser.user.id}`"
        :user="viewingUser.user"
        :editing="viewingUser.editing"
        :app="viewingUser.app"
      />
    </CommonSectionMenu>
    <CommonSectionMenu
      v-if="userViewingTicket.idleUsers.length > 0"
      class="!py-4"
      :header-label="__('Opened in tabs')"
      :help="
        __(
          'Has ticket open in tabs, but is not actively looking at the ticket.',
        )
      "
    >
      <TicketViewerItem
        v-for="(idleUser, index) in userViewingTicket.idleUsers"
        :key="`${index}-${idleUser.user.id}`"
        :user="idleUser.user"
        :editing="idleUser.editing"
        :app="idleUser.app"
        idle
      />
    </CommonSectionMenu>
  </CommonDialog>
</template>
