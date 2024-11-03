<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { storeToRefs } from 'pinia'
import { computed } from 'vue'

import CommonPopover from '#shared/components/CommonPopover/CommonPopover.vue'
import { usePopover } from '#shared/components/CommonPopover/usePopover.ts'
import CommonUserAvatar from '#shared/components/CommonUserAvatar/CommonUserAvatar.vue'
import { useSessionStore } from '#shared/stores/session.ts'

import CommonPopoverMenu from '#desktop/components/CommonPopoverMenu/CommonPopoverMenu.vue'
import { avatarMenuItems } from '#desktop/components/layout/LayoutSidebar/LeftSidebar/AvatarMenu/plugins/index.ts'
import { useCollapsedState } from '#desktop/components/layout/LayoutSidebar/LeftSidebar/useCollapsedState.ts'

const { user } = storeToRefs(useSessionStore())

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
    class="-:outline-transparent hover:-:outline-blue-900 rounded-full outline outline-2 focus-visible:outline-blue-800 hover:focus-visible:outline-blue-800"
    :class="{
      'outline-blue-800 hover:outline-blue-800': popoverIsOpen,
    }"
    :aria-label="user?.fullname || user?.email || $t('User menu')"
    aria-controls="user-menu-popover"
    aria-expanded="false"
    @click="toggle(true)"
  >
    <CommonUserAvatar
      v-if="user"
      :entity="user"
      class="!flex"
      :size="avatarSize"
      personal
    />
  </button>
</template>
