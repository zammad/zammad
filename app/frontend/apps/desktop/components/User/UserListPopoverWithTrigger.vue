<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import type { Props as CommonUserAvatarProps } from '#shared/components/CommonUserAvatar/CommonUserAvatar.vue'
import type { TicketLiveAppUser } from '#shared/entities/ticket/types.ts'
import type { User } from '#shared/graphql/types.ts'

import { type Props as CommonPopoverProps } from '#desktop//components/CommonPopover/CommonPopover.vue'
import CommonPopoverWithTrigger from '#desktop/components/CommonPopover/CommonPopoverWithTrigger.vue'
import UserListPopover from '#desktop/components/User/UserListPopoverWithTrigger/UserListPopover.vue'

export interface Props {
  users: User[]
  liveUsers?: Pick<TicketLiveAppUser, 'editing' | 'app' | 'isIdle'>[]
  popoverConfig?: Omit<CommonPopoverProps, 'owner'>
  avatarConfig?: Omit<CommonUserAvatarProps, 'entity'>
  triggerClass?: string
  noFocusStyling?: boolean
  noHoverStyling?: boolean
  zIndex?: string
}

const props = defineProps<Props>()

defineOptions({
  inheritAttrs: false,
})

defineSlots<{
  default(props: {
    isOpen?: boolean | undefined
    popoverId?: string
    hasOpenViaLongClick?: boolean
  }): never
}>()

const overflowCount = computed(() => {
  if (props.users.length > 99) return '+99'
  return `+${props.users.length}`
})
</script>

<template>
  <CommonPopoverWithTrigger
    :class="[
      !$slots?.default?.() ? 'rounded-full! focus-visible:outline-2!' : '',
      triggerClass ?? '',
    ]"
    :no-hover-styling="noHoverStyling"
    :no-focus-styling="noFocusStyling"
    :z-index="zIndex"
    :trigger-link-active-class="
      !$slots?.default?.()
        ? 'outline-2! outline-offset-1! outline-blue-800! hover:outline-blue-800!'
        : ''
    "
    v-bind="{ ...popoverConfig, ...$attrs }"
  >
    <template #popover-content="{ popoverId, hasOpenedViaLongClick }">
      <UserListPopover
        :id="popoverId"
        :users="users"
        :live-users="liveUsers"
        :has-open-via-long-click="hasOpenedViaLongClick"
      />
    </template>

    <template #default="slotProps">
      <slot v-bind="slotProps">
        <div
          class="flex h-8 w-8 items-center justify-center rounded-full bg-green-200 text-sm text-gray-300 dark:bg-gray-600 dark:text-neutral-400"
        >
          {{ overflowCount }}
        </div>
      </slot>
    </template>
  </CommonPopoverWithTrigger>
</template>
