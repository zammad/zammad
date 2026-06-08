<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { toRef } from 'vue'

import type { AvatarUser } from '#shared/components/CommonUserAvatar/types.ts'
import { useUserEntity } from '#shared/entities/user/composables/useUserEntity.ts'

import UserPopoverWithTrigger from '#desktop/components/User/UserPopoverWithTrigger.vue'

import type { QuickSearchPluginProps } from '../../types.ts'

const props = defineProps<QuickSearchPluginProps>()

const { userDisplayName, isUserInactive } = useUserEntity(toRef(props, 'item'))
</script>

<template>
  <UserPopoverWithTrigger
    :popover-config="{ orientation: 'right' }"
    z-index="52"
    class="group/item flex grow items-center gap-2 rounded-md px-2 py-3 text-neutral-400 hover:bg-blue-900 hover:no-underline!"
    trigger-link-active-class="outline-2! outline-offset-1! outline-blue-800! hover:outline-blue-800!"
    :user="item as AvatarUser"
    :aria-description="isUserInactive ? $t('User is inactive.') : undefined"
  >
    <CommonIcon
      class="shrink-0 text-neutral-500"
      :name="isUserInactive ? 'user-inactive' : 'user'"
      size="tiny"
      decorative
    />
    <CommonLabel
      class="block! truncate group-hover/item:text-white"
      :class="{
        'text-neutral-500! group-hover/item:text-white!': isUserInactive,
      }"
    >
      {{ userDisplayName }}
    </CommonLabel>
  </UserPopoverWithTrigger>
</template>
