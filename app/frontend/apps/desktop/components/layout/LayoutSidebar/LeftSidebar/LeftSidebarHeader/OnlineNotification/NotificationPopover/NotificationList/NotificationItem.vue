<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { toRef } from 'vue'

import CommonUserAvatar from '#shared/components/CommonUserAvatar/CommonUserAvatar.vue'
import { useActivityMessage } from '#shared/composables/activity-message/useActivityMessage.ts'
import type { OnlineNotification } from '#shared/graphql/types.ts'

import AiAgentAvatar from '#desktop/components/AiAgent/AiAgentAvatar.vue'
import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'

interface Props {
  notification: OnlineNotification
}

const props = defineProps<Props>()

const emit = defineEmits<{
  visited: [OnlineNotification]
  seen: [OnlineNotification]
  remove: [OnlineNotification]
}>()

const { link, builder, highlightedMessage } = useActivityMessage(toRef(props, 'notification'))

const handleLinkClick = (notification: OnlineNotification) => {
  if (link) emit('visited', notification)
  if (!notification.seen) emit('seen', notification)
}
</script>

<template>
  <li class="py-2 first:pt-0 last:pb-0">
    <div class="group isolate flex items-center justify-between gap-3">
      <component
        :is="link ? 'CommonLink' : 'div'"
        v-if="builder"
        v-tooltip="!link ? $t('Mark as read') : undefined"
        class="grid cursor-default grid-cols-[1fr_auto] grid-rows-[auto_auto] gap-x-2 hover:no-underline!"
        :class="{
          'group/link': link,
          'opacity-30': notification.seen,
          'cursor-pointer': !notification.seen,
        }"
        :link="link ? `/${link}` : undefined"
        @click="handleLinkClick(notification)"
      >
        <AiAgentAvatar v-if="notification?.meta?.createdByAi" class="col-start-1 row-span-2" />
        <CommonUserAvatar
          v-else-if="notification.createdBy"
          :entity="notification.createdBy"
          size="small"
          class="col-start-1 row-span-2"
          no-indicator
          no-muted
        />
        <CommonIcon
          v-else
          class="col-start-1 row-span-2 m-2.5 self-center text-red-500"
          size="xs"
          role="presentation"
          name="x-lg"
        />

        <!--   eslint-disable vue/no-v-text-v-html-on-component vue/no-v-html   -->
        <CommonLabel
          :id="`notification-${notification.id}`"
          tag="p"
          class="inline! text-lg leading-5 wrap-anywhere text-black dark:text-white"
          :class="{ 'group-hover/link:underline': notification.createdBy }"
          v-html="highlightedMessage"
        />

        <CommonDateTime
          class="col-start-2 row-2 text-xs text-gray-100 dark:text-neutral-500"
          :date-time="notification.createdAt"
          type="relative"
        />
      </component>

      <CommonButton
        :aria-labelledby="`notification-${notification.id}`"
        :aria-description="$t('Remove notification')"
        class="opacity-0 group-hover:opacity-100 focus-visible:opacity-100"
        icon="x-lg"
        variant="remove"
        @click="$emit('remove', notification)"
      />
    </div>
  </li>
</template>
