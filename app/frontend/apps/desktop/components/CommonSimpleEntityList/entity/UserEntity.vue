<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonUserAvatar from '#shared/components/CommonUserAvatar/CommonUserAvatar.vue'
import type { User } from '#shared/graphql/types.ts'

import type { EntityType } from '#desktop/components/CommonSimpleEntityList/types.ts'
import UserPopoverWithTrigger from '#desktop/components/User/UserPopoverWithTrigger.vue'

interface Props {
  entity: User
  context: {
    type: EntityType
    emptyMessage: string
  }
}

defineProps<Props>()
</script>

<template>
  <UserPopoverWithTrigger no-focus-styling :user="entity">
    <template #default="slotProps">
      <div class="flex items-center gap-2">
        <CommonUserAvatar
          class="rounded-full outline-2 outline-transparent group-hover:outline-blue-900 group-focus-visible:outline-blue-900"
          :class="{
            'outline-2! outline-blue-800!':
              slotProps?.isOpen && slotProps.hasOpenViaLongClick,
          }"
          :entity="entity"
        />
        <CommonLabel class="block truncate">{{ entity.fullname }}</CommonLabel>
      </div>
    </template>
  </UserPopoverWithTrigger>
</template>
