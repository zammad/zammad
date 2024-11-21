<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useOnlineNotificationActions } from '#shared/entities/online-notification/composables/useOnlineNotificationActions.ts'
import type { OnlineNotification, Scalars } from '#shared/graphql/types.ts'

import ActivityMessage from './ActivityMessage.vue'

interface Props {
  activity: OnlineNotification
}

const props = defineProps<Props>()

const emit = defineEmits<{
  remove: [id: Scalars['ID']['output']]
  seen: [id: Scalars['ID']['output']]
}>()

const { deleteNotification, deleteNotificationMutation } =
  useOnlineNotificationActions()

const loading = deleteNotificationMutation.loading()

const removeNotification = () => {
  emit('remove', props.activity.id)

  return deleteNotification(props.activity.id)
}
</script>

<template>
  <div class="flex">
    <button
      class="flex items-center ltr:pr-2 rtl:pl-2"
      :class="{ 'cursor-pointer': !loading, 'opacity-50': loading }"
      :disabled="loading"
      @click="removeNotification()"
    >
      <CommonIcon name="delete" class="text-red" size="tiny" />
    </button>
    <div class="flex items-center ltr:pr-2 rtl:pl-2">
      <div
        role="status"
        class="h-3 w-3 rounded-full"
        :class="{ 'bg-blue': !activity.seen }"
        :aria-label="
          activity.seen ? $t('Notification read') : $t('Unread notification')
        "
      ></div>
    </div>
    <ActivityMessage :activity="activity" @seen="$emit('seen', activity.id)" />
  </div>
</template>
