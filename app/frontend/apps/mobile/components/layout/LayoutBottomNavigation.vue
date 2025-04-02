<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->
<script setup lang="ts">
import { storeToRefs } from 'pinia'
import { computed } from 'vue'

import CommonUserAvatar from '#shared/components/CommonUserAvatar/CommonUserAvatar.vue'
import { useOnlineNotificationCount } from '#shared/entities/online-notification/composables/useOnlineNotificationCount.ts'
import { useSessionStore } from '#shared/stores/session.ts'

import { useCustomLayout } from './useCustomLayout.ts'

const { user } = storeToRefs(useSessionStore())
const { isCustomLayout } = useCustomLayout()
const { unseenCount } = useOnlineNotificationCount()

const notificationCount = computed(() => {
  if (!unseenCount.value) return ''
  if (unseenCount.value > 99) return '99+'
  return unseenCount.value.toString()
})
</script>

<template>
  <footer
    class="bottom-navigation bg-gray-light fixed bottom-0 z-10 w-full backdrop-blur-lg"
    :class="{ 'px-4': isCustomLayout }"
    data-bottom-navigation
  >
    <div
      v-if="!isCustomLayout"
      class="flex h-14 w-full items-center text-center"
    >
      <CommonLink
        link="/"
        class="flex flex-1 justify-center"
        exact-active-class="text-blue"
      >
        <CommonIcon name="home" />
      </CommonLink>
      <CommonLink
        link="/notifications"
        exact-active-class="text-blue"
        class="relative flex flex-1 justify-center"
      >
        <div
          v-if="notificationCount"
          role="status"
          :aria-label="$t('Unread notifications')"
          class="bg-blue absolute h-4 min-w-[1rem] rounded-full px-1 text-center text-xs text-black ltr:ml-4 rtl:mr-4"
        >
          {{ notificationCount }}
        </div>
        <CommonIcon name="notification-subscribed" decorative />
      </CommonLink>
      <CommonLink
        link="/account"
        class="group flex flex-1 justify-center"
        exact-active-class="user-active"
      >
        <CommonUserAvatar
          v-if="user"
          :entity="user"
          class="group-[.user-active]:ring-blue group-[.user-active]:rounded-full group-[.user-active]:ring-2"
          size="small"
          personal
        />
      </CommonLink>
    </div>
  </footer>
</template>

<style scoped>
.bottom-navigation {
  padding-bottom: env(safe-area-inset-bottom);
}
</style>
