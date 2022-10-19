<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->
<script setup lang="ts">
import CommonUserAvatar from '@shared/components/CommonUserAvatar/CommonUserAvatar.vue'
import { useSessionStore } from '@shared/stores/session'
import { storeToRefs } from 'pinia'
import { computed } from 'vue'
import { useOnlineNotificationCount } from '@shared/entities/online-notification/composables/useOnlineNotificationCount'
import { useCustomLayout } from './useCustomLayout'

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
    class="fixed bottom-0 z-10 flex h-14 w-full items-center bg-gray-light text-center backdrop-blur-lg"
    :class="{ 'px-4': isCustomLayout }"
    data-bottom-navigation
  >
    <template v-if="!isCustomLayout">
      <CommonLink
        link="/"
        class="flex flex-1 justify-center"
        exact-active-class="text-blue"
      >
        <CommonIcon name="home" size="small" />
      </CommonLink>
      <CommonLink
        link="/notifications"
        exact-active-class="text-blue"
        class="relative flex flex-1 justify-center"
      >
        <div
          v-if="notificationCount"
          role="status"
          :aria-label="__('Unread notifications')"
          class="absolute ml-4 h-4 min-w-[1rem] rounded-full bg-blue px-1 text-center text-xs text-black"
        >
          {{ notificationCount }}
        </div>
        <CommonIcon name="bell" size="medium" />
      </CommonLink>
      <CommonLink
        link="/account"
        class="flex-1"
        exact-active-class="user-active"
      >
        <CommonUserAvatar
          v-if="user"
          :entity="user"
          class="user-avatar"
          size="small"
          personal
        />
      </CommonLink>
    </template>
  </footer>
</template>

<style scoped lang="scss">
.user-active {
  .user-avatar {
    @apply outline outline-2 outline-blue;
  }
}
</style>
