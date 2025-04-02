<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonUserAvatar from '#shared/components/CommonUserAvatar/CommonUserAvatar.vue'
import type { User } from '#shared/graphql/types.ts'

interface Props {
  entity: User
}
defineProps<Props>()
</script>

<template>
  <CommonLink
    :link="`/user/profile/${entity.internalId}`"
    class="flex gap-2 hover:no-underline!"
  >
    <CommonUserAvatar :entity="entity" size="small" />
    <CommonLabel class="text-blue-800! hover:underline dark:text-neutral-400!"
      >{{ `${entity.fullname}` }}
    </CommonLabel>
  </CommonLink>
</template>
