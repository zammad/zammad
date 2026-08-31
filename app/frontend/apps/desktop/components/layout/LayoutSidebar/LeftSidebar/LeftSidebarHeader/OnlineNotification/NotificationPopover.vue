<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useTemplateRef, type Ref } from 'vue'

import type { OnlineNotification } from '#shared/graphql/types.ts'

import CommonLoader from '#desktop/components/CommonLoader/CommonLoader.vue'
import NotificationFooter from '#desktop/components/layout/LayoutSidebar/LeftSidebar/LeftSidebarHeader/OnlineNotification/NotificationPopover/NotificationFooter.vue'
import NotificationList from '#desktop/components/layout/LayoutSidebar/LeftSidebar/LeftSidebarHeader/OnlineNotification/NotificationPopover/NotificationList.vue'
import NotificationListSkeleton from '#desktop/components/layout/LayoutSidebar/LeftSidebar/LeftSidebarHeader/OnlineNotification/NotificationPopover/NotificationListSkeleton.vue'
import { useElementScroll } from '#desktop/composables/useElementScroll.ts'

interface Props {
  notificationList: OnlineNotification[]
  loading: boolean
  hasUnseenNotification: boolean
}

defineProps<Props>()

defineEmits<{
  visited: [OnlineNotification]
  seen: [OnlineNotification]
  remove: [OnlineNotification]
  'seen-all': []
  'clear-all': []
}>()

const scrollContainerElement = useTemplateRef('scrollContainer')

const { reachedTop, isScrollable } = useElementScroll(scrollContainerElement as Ref<HTMLElement>)
</script>

<template>
  <section class="flex max-h-full w-110 flex-col">
    <header
      class="rounded-t-xl bg-neutral-50 p-3 dark:bg-gray-500"
      :class="{
        'border-b border-b-neutral-300 dark:border-b-gray-900': !reachedTop,
      }"
    >
      <CommonLabel size="small" class="dark:text-neutral-500" tag="h3">
        {{ $t('Notifications') }}
      </CommonLabel>
    </header>

    <div ref="scrollContainer" class="min-h-0 flex-1 overflow-y-auto pt-2">
      <CommonLoader class="px-2.5 pb-2.5" :loading="loading">
        <template #skeleton>
          <NotificationListSkeleton v-for="n in 3" :key="n" />
        </template>

        <NotificationList
          :class="{ 'ltr:pr-5 rtl:pl-5': isScrollable }"
          :list="notificationList"
          @visited="$emit('visited', $event)"
          @seen="$emit('seen', $event)"
          @remove="$emit('remove', $event)"
        />
      </CommonLoader>
    </div>

    <NotificationFooter
      :has-unseen-notification="hasUnseenNotification"
      :has-notifications="notificationList.length > 0"
      @mark-all="$emit('seen-all')"
      @clear-all="$emit('clear-all')"
    />
  </section>
</template>
