<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import ActivityMessage from '#shared/components/ActivityMessage/ActivityMessage.vue'
import type { AvatarUser } from '#shared/components/CommonUserAvatar/types.ts'
import { useOnlineNotificationDeleteMutation } from '#shared/entities/online-notification/graphql/mutations/delete.api.ts'
import type {
  ActivityMessageMetaObject,
  Scalars,
} from '#shared/graphql/types.ts'
import { MutationHandler } from '#shared/server/apollo/handler/index.ts'

import type { ApolloCache, InMemoryCache } from '@apollo/client'

export interface Props {
  itemId: Scalars['ID']['output']
  objectName: string
  typeName: string
  seen: boolean
  metaObject?: Maybe<ActivityMessageMetaObject>
  createdAt: string
  createdBy?: Maybe<AvatarUser>
}

const props = defineProps<Props>()

const emit = defineEmits<{
  remove: [id: Scalars['ID']['output']]
  seen: [id: Scalars['ID']['output']]
}>()

const updateCacheAfterRemoving = (
  cache: ApolloCache<InMemoryCache>,
  id: Scalars['ID']['output'],
) => {
  const normalizedId = cache.identify({ id, __typename: 'OnlineNotification' })
  cache.evict({ id: normalizedId })
  cache.gc()
}

const removeNotificationMutation = new MutationHandler(
  useOnlineNotificationDeleteMutation(() => ({
    variables: { onlineNotificationId: props.itemId },
    update(cache) {
      updateCacheAfterRemoving(cache, props.itemId)
    },
  })),
  {
    errorNotificationMessage: __('The notifcation could not be deleted.'),
  },
)

const loading = removeNotificationMutation.loading()

const removeNotification = () => {
  emit('remove', props.itemId)

  return removeNotificationMutation.send()
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
        :class="{ 'bg-blue': !seen }"
        :aria-label="seen ? $t('Notification read') : $t('Unread notification')"
      ></div>
    </div>
    <ActivityMessage
      :type-name="typeName"
      :object-name="objectName"
      :created-at="createdAt"
      :created-by="createdBy"
      :meta-object="metaObject"
      @seen="$emit('seen', itemId)"
    />
  </div>
</template>
