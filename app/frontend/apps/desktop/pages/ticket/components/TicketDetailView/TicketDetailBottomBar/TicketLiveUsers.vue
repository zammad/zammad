<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, toRef } from 'vue'

import { useTicketLiveUsersDisplay } from '#shared/entities/ticket/composables/useTicketLiveUsersDisplay.ts'
import type { TicketLiveAppUser } from '#shared/entities/ticket/types.ts'

import AiAgentPopoverWithTrigger from '#desktop/components/AiAgent/AiAgentPopoverWithTrigger.vue'
import UserListPopoverWithTrigger from '#desktop/components/User/UserListPopoverWithTrigger.vue'
import UserPopoverWithTrigger from '#desktop/components/User/UserPopoverWithTrigger.vue'
import { useTicketInformation } from '#desktop/pages/ticket/composables/useTicketInformation.ts'

export interface Props {
  liveUserList?: TicketLiveAppUser[]
}

const props = withDefaults(defineProps<Props>(), {
  liveUserList: () => [],
})

const { liveUsers } = useTicketLiveUsersDisplay(toRef(props, 'liveUserList'))

const LIVE_USER_LIMIT = 9

const visibleLiveUsers = computed(() => {
  if (liveUsers.value.length <= LIVE_USER_LIMIT) return liveUsers.value
  return liveUsers.value.slice(0, LIVE_USER_LIMIT - 1)
})

const overflowLiveUsers = computed(() => {
  if (liveUsers.value.length <= LIVE_USER_LIMIT) return []
  return liveUsers.value.slice(LIVE_USER_LIMIT - 1)
})

const { ticket } = useTicketInformation()
</script>

<template>
  <div class="flex items-center gap-2">
    <AiAgentPopoverWithTrigger v-if="ticket?.aiAgentRunning" />

    <template v-if="liveUserList?.length">
      <UserPopoverWithTrigger
        v-for="liveUser in visibleLiveUsers"
        :key="liveUser.user.id"
        :user="liveUser.user"
        :avatar-config="{
          live: liveUser,
          size: 'small',
        }"
        :popover-config="{
          placement: 'arrowStart',
        }"
      />
      <UserListPopoverWithTrigger
        v-if="overflowLiveUsers.length"
        :users="overflowLiveUsers.map((liveUser) => liveUser.user)"
        :live-users="
          overflowLiveUsers.map((liveUser) => ({
            editing: liveUser.editing,
            app: liveUser.app,
            isIdle: liveUser.isIdle,
          }))
        "
        :popover-config="{
          placement: 'arrowStart',
        }"
      />
    </template>
  </div>
</template>
