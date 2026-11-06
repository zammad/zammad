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
  action: [Notification]
  close: [Notification, boolean?]
}>()

const notificationTypeClassMap = getNotificationClasses()

const closesOnClick = computed(
  () => !props.notification.persistent && props.notification.currentProgress === undefined,
)

const maxProgress = computed<number>(() => props.notification.maxProgress ?? 1)

const notificationMessageHtml = computed(() =>
  markup(i18n.t(props.notification.message, ...(props.notification.messagePlaceholder || []))),
)
</script>

<template>
  <!-- eslint-disable vuejs-accessibility/no-static-element-interactions -->
  <Component
    :is="closesOnClick ? 'button' : 'div'"
    class="flex flex-col gap-2 text-start"
    :class="{ 'cursor-pointer': closesOnClick }"
    data-test-id="notification"
    @keydown.enter="closesOnClick ? emit('close', notification) : undefined"
    @click="closesOnClick ? emit('close', notification) : undefined"
  >
    <div class="flex items-start gap-1.5">
      <CommonIcon
        class="mt-0.5 shrink-0"
        :name="`common-notification-${notification.type}`"
        size="tiny"
        decorative
      />

      <div class="flex min-w-0 grow flex-col gap-1.5">
        <!-- eslint-disable vue/no-v-html -->
        <p
          class="text-sm"
          :class="notificationTypeClassMap.message"
          v-html="notificationMessageHtml"
        />

        <CommonProgressBar
          v-if="notification.currentProgress !== undefined"
          class="min-w-64"
          size="small"
          variant="inverted"
          :max="maxProgress.toString()"
          :value="
            notification.currentProgress ? notification.currentProgress.toString() : undefined
          "
        />
      </div>
    </div>

    <div v-if="notification.persistent" class="flex items-center justify-end gap-1">
      <button
        v-if="notification.actionLabel && notification.actionCallback"
        :class="notificationTypeClassMap.button"
        @click.stop="emit('action', notification)"
      >
        {{ $t(notification.actionLabel) }}
      </button>

      <button
        :class="notificationTypeClassMap.button"
        :aria-label="$t('Hide notification')"
        @click.stop="emit('close', notification, true)"
      >
        {{ $t(notification.closeLabel || __('Hide')) }}
      </button>
    </div>
  </Component>
</template>
