<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, toRef } from 'vue'

import CommonUserAvatar from '#shared/components/CommonUserAvatar/CommonUserAvatar.vue'
import { useTicketLiveUsersDisplay } from '#shared/entities/ticket/composables/useTicketLiveUsersDisplay.ts'
import type { TicketLiveAppUser } from '#shared/entities/ticket/types.ts'
import { EnumTaskbarApp } from '#shared/graphql/types.ts'

export interface Props {
  liveUserList: TicketLiveAppUser[]
}

const props = defineProps<Props>()

const { liveUsers } = useTicketLiveUsersDisplay(toRef(props, 'liveUserList'))

const LIVE_USER_LIMIT = 9

const visibleLiveUsers = computed(() =>
  liveUsers.value.slice(0, LIVE_USER_LIMIT),
)

const liveUsersOverflow = computed(() => {
  if (liveUsers.value.length <= LIVE_USER_LIMIT) return
  const overflow = liveUsers.value.length - LIVE_USER_LIMIT
  if (overflow > 999) return '+999'
  return `+${overflow}`
})

const isLiveUserIdle = (liveUser: TicketLiveAppUser) => liveUser.isIdle

const isLiveUserEditing = (liveUser: TicketLiveAppUser) => liveUser.editing

const isLiveUserMobile = (liveUser: TicketLiveAppUser) =>
  liveUser.app === EnumTaskbarApp.Mobile
</script>

<template>
  <div class="flex items-center gap-2.5 ltr:mr-auto rtl:ml-auto">
    <div
      v-for="liveUser in visibleLiveUsers"
      :key="liveUser.user.id"
      class="relative"
      :class="{
        'opacity-50 grayscale': isLiveUserIdle(liveUser),
      }"
    >
      <CommonUserAvatar :entity="liveUser.user" />
      <div
        v-if="isLiveUserEditing(liveUser) || isLiveUserMobile(liveUser)"
        class="absolute bottom-0 end-0 flex translate-y-1 items-center justify-center rounded-full bg-blue-200 p-[3px] outline outline-1 -outline-offset-1 outline-neutral-100 ltr:translate-x-2 rtl:-translate-x-2 dark:bg-gray-700 dark:outline-gray-900"
      >
        <CommonIcon
          class="text-black dark:text-white"
          :label="__('Editing on Mobile')"
          size="xs"
          :name="
            isLiveUserEditing(liveUser) && isLiveUserMobile(liveUser)
              ? 'phone-pencil'
              : isLiveUserMobile(liveUser)
                ? 'mobile'
                : 'pencil'
          "
        />
      </div>
    </div>
    <div
      v-if="liveUsersOverflow"
      class="flex h-10 w-10 items-center justify-center rounded-full bg-blue-200 text-sm outline outline-1 -outline-offset-1 outline-neutral-100 dark:bg-gray-700 dark:outline-gray-900"
    >
      {{ liveUsersOverflow }}
    </div>
  </div>
</template>
