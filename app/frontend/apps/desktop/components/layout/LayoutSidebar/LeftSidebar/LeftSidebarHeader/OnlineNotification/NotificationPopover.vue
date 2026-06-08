<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useTemplateRef, type Ref } from 'vue'

import type { OnlineNotification } from '#shared/graphql/types.ts'

import CommonLoader from '#desktop/components/CommonLoader/CommonLoader.vue'
import NotificationHeader from '#desktop/components/layout/LayoutSidebar/LeftSidebar/LeftSidebarHeader/OnlineNotification/NotificationPopover/NotificationHeader.vue'
import NotificationList from '#desktop/components/layout/LayoutSidebar/LeftSidebar/LeftSidebarHeader/OnlineNotification/NotificationPopover/NotificationList.vue'
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
}>()

const sectionElement = useTemplateRef('section')

const { reachedTop, isScrollable } = useElementScroll(sectionElement as Ref<HTMLElement>)
</script>

<template>
  <section ref="section" class="scroll max-h-full w-[400px] overflow-y-auto">
    <NotificationHeader
      class="sticky top-0 z-10 mb-2 bg-neutral-50 px-3 py-3 dark:bg-gray-500"
      :class="{
        'border-b border-b-neutral-300 dark:border-b-gray-900': !reachedTop,
      }"
      :has-unseen-notification="hasUnseenNotification"
      @mark-all="$emit('seen-all')"
    />
    <CommonLoader :loading="loading">
      <NotificationList
        :class="{ 'ltr:pr-5 rtl:pl-5': isScrollable }"
        :list="notificationList"
        @visited="$emit('visited', $event)"
        @seen="$emit('seen', $event)"
        @remove="$emit('remove', $event)"
      />
    </CommonLoader>
  </section>
</template>
