<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { toRef } from 'vue'

import CommonAvatar from '#shared/components/CommonAvatar/CommonAvatar.vue'
import CommonUserAvatar from '#shared/components/CommonUserAvatar/CommonUserAvatar.vue'
import { useActivityMessage } from '#shared/composables/activity-message/useActivityMessage.ts'
import type { OnlineNotification } from '#shared/graphql/types.ts'
import { markup } from '#shared/utils/markup.ts'

interface Props {
  activity: OnlineNotification
}

const props = defineProps<Props>()

const { builder, message, link } = useActivityMessage(toRef(props, 'activity'))

defineEmits<{
  seen: []
}>()
</script>

<template>
  <component
    :is="link ? 'CommonLink' : 'div'"
    v-if="builder"
    class="flex flex-1 border-b border-white/10 py-4"
    :class="{
      'cursor-pointer': !activity.seen,
    }"
    :link="link ? link : undefined"
    :aria-label="!link ? $t('Mark as read') : undefined"
    @click="!link && !activity.seen && $emit('seen')"
  >
    <div class="flex items-center ltr:mr-4 rtl:ml-4">
      <CommonUserAvatar
        v-if="activity.createdBy"
        :entity="activity.createdBy"
        no-indicator
        no-muted
      />
      <CommonAvatar v-else class="bg-red-bright text-white" icon="lock" />
    </div>

    <div class="flex flex-col">
      <!--  eslint-disable vue/no-v-html -->
      <div class="text-lg leading-5" v-html="markup(message)" />
      <div class="mt-1 flex text-gray">
        <CommonDateTime :date-time="activity.createdAt" type="relative" />
      </div>
    </div>
  </component>
</template>
