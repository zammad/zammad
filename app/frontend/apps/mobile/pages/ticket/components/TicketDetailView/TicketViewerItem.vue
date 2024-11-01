<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, toRef } from 'vue'

import CommonUserAvatar from '#shared/components/CommonUserAvatar/CommonUserAvatar.vue'
import {
  type AvatarUser,
  type AvatarUserLive,
} from '#shared/components/CommonUserAvatar/types.ts'
import { useAvatarIndicator } from '#shared/composables/useAvatarIndicator.ts'
import { EnumTaskbarApp } from '#shared/graphql/types.ts'
import { getIdFromGraphQLId } from '#shared/graphql/utils.ts'

export interface Props {
  user: AvatarUser
  editing: boolean
  idle?: boolean
  app: EnumTaskbarApp
}

const props = defineProps<Props>()

const liveUser = computed<AvatarUserLive>(() => ({
  editing: props.editing,
  app: props.app,
  isIdle: props.idle,
}))

const { indicatorIcon, indicatorLabel, indicatorIsIdle } = useAvatarIndicator(
  toRef(props.user),
  false,
  liveUser,
)
</script>

<template>
  <CommonLink
    :key="user.id"
    :link="`/users/${getIdFromGraphQLId(user.id)}`"
    class="flex items-center justify-between px-3 first:pt-1 last:pb-1"
  >
    <div class="flex items-center">
      <CommonUserAvatar :entity="user" :live="{ isIdle: idle }" />
      <div class="ltr:ml-3 rtl:mr-3">{{ user.fullname }}</div>
    </div>

    <div v-if="indicatorIcon" class="flex items-center">
      <CommonIcon
        :class="{ 'fill-gray': indicatorIsIdle }"
        :label="indicatorLabel"
        :name="indicatorIcon"
      />
    </div>
  </CommonLink>
</template>
