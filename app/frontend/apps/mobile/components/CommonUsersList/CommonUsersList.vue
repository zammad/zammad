<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import type { AvatarUser } from '@shared/components/CommonUserAvatar'
import CommonUserAvatar from '@shared/components/CommonUserAvatar/CommonUserAvatar.vue'

interface Props {
  users: (AvatarUser & { internalId: number })[]
}

defineProps<Props>()
</script>

<template>
  <CommonLink
    v-for="user of users"
    :key="user.id"
    :link="`/users/${user.internalId}`"
    class="flex h-14 items-center"
  >
    <CommonUserAvatar decorative :entity="user" class="ltr:mr-3 rtl:ml-3" />
    <span class="overflow-hidden text-ellipsis whitespace-nowrap">
      {{ user.fullname }}
    </span>
  </CommonLink>
</template>
