<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonPopover from '#shared/components/CommonPopover/CommonPopover.vue'
import { usePopover } from '#shared/components/CommonPopover/usePopover.ts'
import { useOnlineNotificationCount } from '#shared/entities/online-notification/composables/useOnlineNotificationCount.ts'

import NotificationButton from '#desktop/components/layout/LayoutSidebar/LeftSidebar/LeftSidebarHeader/OnlineNotification/NotificationButton.vue'
import NotificationPopover from '#desktop/components/layout/LayoutSidebar/LeftSidebar/LeftSidebarHeader/OnlineNotification/NotificationPopover.vue'

const { unseenCount } = useOnlineNotificationCount()

const { popover, popoverTarget, toggle, close } = usePopover()
</script>

<template>
  <div
    id="app-online-notification"
    ref="popoverTarget"
    :aria-label="$t('Notifications')"
    class="relative"
  >
    <NotificationButton :unseen-count="unseenCount" @show="toggle(true)" />

    <CommonPopover ref="popover" orientation="right" :owner="popoverTarget">
      <NotificationPopover :unseen-count="unseenCount" @close="close" />
    </CommonPopover>
  </div>
</template>
