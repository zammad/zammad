<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import ActivityMessage from '@shared/components/ActivityMessage/ActivityMessage.vue'
import type { ActivityMessageMetaObject, Scalars } from '@shared/graphql/types'
import type { AvatarUser } from '@shared/components/CommonUserAvatar'

export interface Props {
  itemId: Scalars['ID']
  objectName: string
  typeName: string
  seen: boolean
  metaObject: ActivityMessageMetaObject
  createdAt: string
  createdBy: AvatarUser
}

defineProps<Props>()

defineEmits<{
  (e: 'remove', id: Scalars['ID']): void
}>()
</script>

<template>
  <div class="flex">
    <div class="flex items-center ltr:pr-2 rtl:pl-2">
      <CommonIcon
        name="mobile-delete"
        class="cursor-pointer text-red"
        size="tiny"
        @click="$emit('remove', itemId)"
      />
    </div>
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
    />
  </div>
</template>
