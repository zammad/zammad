<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, toRef } from 'vue'

import { useTaskbarLiveUsersDisplay } from '#shared/entities/taskbar/composables/useTaskbarLiveUsersDisplay.ts'
import type { TaskbarLiveAppUser } from '#shared/entities/taskbar/types.ts'

import UserListPopoverWithTrigger from '#desktop/components/User/UserListPopoverWithTrigger.vue'
import UserPopoverWithTrigger from '#desktop/components/User/UserPopoverWithTrigger.vue'

export interface Props {
  liveUserList?: TaskbarLiveAppUser[]
}

const props = withDefaults(defineProps<Props>(), {
  liveUserList: () => [],
})

const { liveUsers } = useTaskbarLiveUsersDisplay(toRef(props, 'liveUserList'))

// Same as the ticket detail view: past this many the rest collapses into one popover, so the row
//   cannot push the buttons next to it off the bar.
const LIVE_USER_LIMIT = 9

const visibleLiveUsers = computed(() => {
  if (liveUsers.value.length <= LIVE_USER_LIMIT) return liveUsers.value
  return liveUsers.value.slice(0, LIVE_USER_LIMIT - 1)
})

const overflowLiveUsers = computed(() => {
  if (liveUsers.value.length <= LIVE_USER_LIMIT) return []
  return liveUsers.value.slice(LIVE_USER_LIMIT - 1)
})
</script>

<template>
  <div v-if="liveUserList.length" class="flex items-center gap-2">
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
  </div>
</template>
