<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonUserAvatar from '#shared/components/CommonUserAvatar/CommonUserAvatar.vue'
import type { User } from '#shared/graphql/types.ts'

import type { Orientation } from '#desktop/components/CommonPopover/types.ts'
import type { EntityType } from '#desktop/components/CommonSimpleEntityList/types.ts'
import UserPopoverWithTrigger from '#desktop/components/User/UserPopoverWithTrigger.vue'

interface Props {
  entity: User
  context: {
    type: EntityType
    emptyMessage?: string
    hasPopover?: boolean
    popoverOrientation?: Orientation
  }
}

defineProps<Props>()
</script>

<template>
  <UserPopoverWithTrigger
    v-if="context.hasPopover"
    :popover-config="{ orientation: context.popoverOrientation ?? 'left' }"
    no-focus-styling
    :user="entity"
  >
    <template #default="slotProps">
      <div class="flex items-center gap-2">
        <CommonUserAvatar
          class="rounded-full outline-1 outline-transparent group-hover:outline-blue-600 group-focus-visible:outline-blue-800 group-hover:dark:outline-blue-900"
          :class="{
            'outline-2! outline-blue-800!': slotProps?.isOpen && slotProps.hasOpenViaLongClick,
          }"
          :entity="entity"
          size="small"
        />
        <CommonLabel
          class="line-clamp-2! break-word text-blue-800! group-hover:text-blue-850! group-focus-visible:text-blue-800! group-hover:dark:text-blue-600!"
        >
          {{ entity.fullname }}
        </CommonLabel>
      </div>
    </template>
  </UserPopoverWithTrigger>
  <template v-else>
    <CommonLink
      :link="`/users/${entity.internalId}`"
      class="group flex items-center gap-2 hover:no-underline!"
    >
      <CommonUserAvatar
        class="rounded-full outline-1 outline-transparent group-hover:outline-blue-900 group-focus-visible:outline-blue-900"
        :entity="entity"
        size="small"
      />
      <CommonLabel
        class="line-clamp-2! break-word text-blue-800! group-hover:text-blue-850! group-focus-visible:text-blue-800! group-hover:dark:text-blue-600!"
      >
        {{ entity.fullname }}
      </CommonLabel>
    </CommonLink>
  </template>
</template>
