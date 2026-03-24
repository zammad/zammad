<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import CommonProgressBar from '#shared/components/CommonProgressBar/CommonProgressBar.vue'
import { i18n } from '#shared/i18n.ts'
import { getNotificationClasses } from '#shared/initializer/initializeNotificationClasses.ts'
import { markup } from '#shared/utils/markup.ts'

import type { Notification } from './types.ts'

interface Props {
  notification: Notification
}

const props = defineProps<Props>()

const emit = defineEmits<{
  close: [Notification, boolean?]
}>()

const notificationTypeClassMap = getNotificationClasses()

const maxProgress = computed<number>(() => props.notification.maxProgress ?? 1)

const notificationMessageHtml = computed(() =>
  markup(i18n.t(props.notification.message, ...(props.notification.messagePlaceholder || []))),
)
</script>

<template>
  <!-- eslint-disable vuejs-accessibility/no-static-element-interactions -->
  <Component
    :is="notification.persistent || notification.currentProgress !== undefined ? 'div' : 'button'"
    data-test-id="notification"
    @keydown.enter="emit('close', notification)"
    @click="emit('close', notification)"
  >
    <CommonIcon
      class="col-span-1 self-center"
      :name="`common-notification-${notification.type}`"
      size="tiny"
      decorative
    />

    <!-- eslint-disable vue/no-v-html -->
    <p
      class="col-start-2 self-center text-sm"
      :class="[
        notificationTypeClassMap.message,
        {
          'cursor-default': notification.persistent || notification.currentProgress !== undefined,
        },
      ]"
      v-html="notificationMessageHtml"
    />

    <button
      v-if="notification.persistent"
      class="col-start-3 ps-2.5 pe-1.5 text-sm leading-snug transition-colors hover:text-black focus-visible:text-white focus-visible:outline-none dark:hover:text-white"
      :class="{
        'row-span-2': notification.currentProgress !== undefined,
      }"
      :aria-label="$t('Hide notification')"
      @click.stop="emit('close', notification, true)"
    >
      {{ $t('Hide') }}
    </button>

    <CommonProgressBar
      v-if="notification.currentProgress !== undefined"
      class="col-row-2 col-start-2 col-end-3 w-full"
      size="small"
      variant="inverted"
      :max="maxProgress.toString()"
      :value="notification.currentProgress ? notification.currentProgress.toString() : undefined"
    />
  </Component>
</template>
