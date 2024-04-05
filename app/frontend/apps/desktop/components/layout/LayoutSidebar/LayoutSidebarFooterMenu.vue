<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'
import { storeToRefs } from 'pinia'

import { useSessionStore } from '#shared/stores/session.ts'
import CommonUserAvatar from '#shared/components/CommonUserAvatar/CommonUserAvatar.vue'

import CommonPopover from '#desktop/components/CommonPopover/CommonPopover.vue'
import CommonPopoverMenu from '#desktop/components/CommonPopover/CommonPopoverMenu.vue'
import { usePopover } from '#desktop/components/CommonPopover/usePopover.ts'
import { avatarMenuItems } from './AvatarMenu/plugins/index.ts'

interface Props {
  collapsed?: boolean
}

const props = defineProps<Props>()

const { user } = storeToRefs(useSessionStore())

const avatarSize = computed(() => (props.collapsed ? 'small' : 'normal'))

const { popover, popoverTarget, toggle, isOpen: popoverIsOpen } = usePopover()
</script>

<template>
  <section class="flex flex-row justify-between items-center">
    <CommonPopover
      id="user-menu-popover"
      ref="popover"
      :owner="popoverTarget"
      :hide-arrow="collapsed"
      orientation="autoVertical"
      placement="start"
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
      class="-:outline-transparent hover:-:outline-blue-900 rounded-full outline outline-2 focus:outline-blue-800 hover:focus:outline-blue-800"
      :class="{
        'outline-blue-800 hover:outline-blue-800': popoverIsOpen,
      }"
      :aria-label="$t('User menu')"
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
    <!-- <ul class="flex flex-row">
      <li>T1</li>
      <li>T2</li>
    </ul> -->
  </section>
</template>
