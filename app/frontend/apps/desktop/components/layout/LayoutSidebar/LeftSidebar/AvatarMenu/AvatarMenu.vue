<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, toRef } from 'vue'

import CommonUserAvatar from '#shared/components/CommonUserAvatar/CommonUserAvatar.vue'
import { useSessionStore } from '#shared/stores/session.ts'

import CommonPopover from '#desktop/components/CommonPopover/CommonPopover.vue'
import { usePopover } from '#desktop/components/CommonPopover/usePopover.ts'
import CommonPopoverMenu from '#desktop/components/CommonPopoverMenu/CommonPopoverMenu.vue'
import { avatarMenuItems } from '#desktop/components/layout/LayoutSidebar/LeftSidebar/AvatarMenu/plugins/index.ts'
import { useCollapsedState } from '#desktop/components/layout/LayoutSidebar/LeftSidebar/useCollapsedState.ts'

const user = toRef(useSessionStore(), 'user')

const { collapsedState } = useCollapsedState()

const avatarSize = computed(() => (collapsedState?.value ? 'small' : 'normal'))

const { popover, popoverTarget, toggle, isOpen: popoverIsOpen } = usePopover()
</script>

<template>
  <CommonPopover
    id="user-menu-popover"
    ref="popover"
    :owner="popoverTarget"
    :hide-arrow="collapsedState"
    z-index="52"
    orientation="autoVertical"
    :placement="collapsedState ? 'start' : 'arrowStart'"
  >
    <CommonPopoverMenu
      :popover="popover"
      :header-label="user?.fullname!"
      :items="avatarMenuItems"
    />
  </CommonPopover>

  <button
    id="user-menu"
    ref="popoverTarget"
    v-tooltip="user?.fullname || user?.email || $t('User menu')"
    class="rounded-full outline-2 outline-transparent hover:outline-blue-900 focus-visible:outline-blue-800 hover:focus-visible:outline-blue-800"
    :class="{
      'outline-blue-800! hover:outline-blue-800!': popoverIsOpen,
    }"
    :aria-label="user?.fullname || user?.email || $t('User menu')"
    aria-controls="user-menu-popover"
    aria-expanded="false"
    @click="toggle(true)"
  >
    <CommonUserAvatar
      v-if="user"
      aria-hidden="true"
      :entity="user"
      class="flex!"
      :size="avatarSize"
      personal
    />
  </button>
</template>
