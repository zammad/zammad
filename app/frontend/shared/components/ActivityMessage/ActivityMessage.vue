<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
/* eslint-disable vue/no-v-html */

import { computed } from 'vue'
import log from '#shared/utils/log.ts'
import type { ActivityMessageMetaObject } from '#shared/graphql/types.ts'
import { userDisplayName } from '#shared/entities/user/utils/getUserDisplayName.ts'
import { markup } from '#shared/utils/markup.ts'
import CommonUserAvatar from '../CommonUserAvatar/CommonUserAvatar.vue'
import CommonAvatar from '../CommonAvatar/CommonAvatar.vue'
import type { AvatarUser } from '../CommonUserAvatar/types.ts'
import { activityMessageBuilder } from './builders/index.ts'

export interface Props {
  typeName: string
  objectName: string
  metaObject?: Maybe<ActivityMessageMetaObject>
  createdAt: string
  createdBy?: Maybe<AvatarUser>
}

const props = defineProps<Props>()

const builder = computed(() => activityMessageBuilder[props.objectName])
if (!builder.value) {
  log.error(`Object missing ${props.objectName}.`)
}

const message = builder.value?.messageText(
  props.typeName,
  props.createdBy ? userDisplayName(props.createdBy) : '',
  props.metaObject,
)

const link = props.metaObject
  ? builder.value?.path(props.metaObject)
  : undefined

if (builder.value && !message) {
  log.error(
    `Unknow action for (${props.objectName}/${props.typeName}), extend activityMessages() of model.`,
  )
}

defineEmits<{
  (e: 'seen'): void
}>()
</script>

<template>
  <component
    :is="link ? 'CommonLink' : 'div'"
    v-if="builder"
    class="flex flex-1 border-b border-white/10 py-4"
    :link="link"
    @click="!link ? $emit('seen') : undefined"
  >
    <div class="flex items-center ltr:mr-4 rtl:ml-4">
      <CommonUserAvatar v-if="createdBy" :entity="createdBy" />
      <CommonAvatar v-else class="bg-red-bright text-white" icon="lock" />
    </div>

    <div class="flex flex-col">
      <div class="text-lg leading-5" v-html="markup(message)" />
      <div class="mt-1 flex text-gray">
        <CommonDateTime :date-time="createdAt" type="relative" />
      </div>
    </div>
  </component>
</template>
