<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
/* eslint-disable vue/no-v-html */

import { computed } from 'vue'
import log from '@shared/utils/log'
import type { ActivityMessageMetaObject } from '@shared/graphql/types'
import { userDisplayName } from '@shared/entities/user/utils/getUserDisplayName'
import { markup } from '@shared/utils/markup'
import CommonUserAvatar from '../CommonUserAvatar/CommonUserAvatar.vue'
import type { AvatarUser } from '../CommonUserAvatar'
import { activityMessageBuilder } from './builders'

export interface Props {
  typeName: string
  objectName: string
  metaObject: ActivityMessageMetaObject
  createdAt: string
  createdBy: AvatarUser
}

const props = defineProps<Props>()

const builder = computed(() => activityMessageBuilder[props.objectName])
if (!builder.value) {
  log.error(`Object missing ${props.objectName}.`)
}

const message = builder.value?.messageText(
  props.typeName,
  userDisplayName(props.createdBy),
  props.metaObject,
)

if (builder.value && !message) {
  log.error(
    `Unknow action for (${props.objectName}/${props.typeName}), extend activityMessages() of model.`,
  )
}
</script>

<template>
  <CommonLink
    v-if="builder"
    class="flex flex-1 border-b border-white/10 py-4"
    :link="builder.path(metaObject)"
  >
    <div class="flex items-center ltr:mr-4 rtl:ml-4">
      <CommonUserAvatar :entity="createdBy" />
    </div>

    <div class="flex flex-col">
      <div class="text-lg leading-5" v-html="markup(message)" />
      <div class="mt-1 flex text-gray">
        <CommonDateTime :date-time="createdAt" type="relative" />
      </div>
    </div>
  </CommonLink>
</template>
