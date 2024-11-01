<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonUserAvatar from '#shared/components/CommonUserAvatar/CommonUserAvatar.vue'
import type {
  AvatarUser,
  AvatarUserAccess,
} from '#shared/components/CommonUserAvatar/types.ts'
import { useAvatarIndicator } from '#shared/composables/useAvatarIndicator.ts'

interface Props {
  users: (AvatarUser & { internalId: number })[]
  accessLookup?: Record<string, { access: AvatarUserAccess }>
}

const props = defineProps<Props>()

const getAvatarIndicator = (user: AvatarUser) => {
  return useAvatarIndicator(
    user,
    false,
    undefined,
    props.accessLookup?.[user.id].access,
  )
}
</script>

<template>
  <CommonLink
    v-for="user of users"
    :key="user.id"
    :link="`/users/${user.internalId}`"
    class="flex h-14 items-center px-3"
  >
    <div class="flex grow items-center">
      <CommonUserAvatar
        class="ltr:mr-3 rtl:ml-3"
        :entity="user"
        :access="accessLookup?.[user.id].access"
        decorative
      />
      <span class="truncate">
        {{ user.fullname }}
      </span>
    </div>
    <div
      v-if="getAvatarIndicator(user).indicatorIcon"
      class="flex items-center"
    >
      <CommonIcon
        :class="{ 'fill-gray': getAvatarIndicator(user).indicatorIsIdle.value }"
        :label="getAvatarIndicator(user).indicatorLabel.value"
        :name="getAvatarIndicator(user).indicatorIcon.value || ''"
      />
    </div>
  </CommonLink>
</template>
