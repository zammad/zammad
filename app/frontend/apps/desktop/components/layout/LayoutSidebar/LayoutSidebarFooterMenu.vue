<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { storeToRefs } from 'pinia'
import { computed } from 'vue'

import CommonPopover from '#shared/components/CommonPopover/CommonPopover.vue'
import { usePopover } from '#shared/components/CommonPopover/usePopover.ts'
import CommonUserAvatar from '#shared/components/CommonUserAvatar/CommonUserAvatar.vue'
import { useTicketCreateView } from '#shared/entities/ticket/composables/useTicketCreateView.ts'
import { useSessionStore } from '#shared/stores/session.ts'

import CommonPopoverMenu from '#desktop/components/CommonPopoverMenu/CommonPopoverMenu.vue'

import { avatarMenuItems } from './AvatarMenu/plugins/index.ts'

interface Props {
  collapsed?: boolean
}

const props = defineProps<Props>()

const { user } = storeToRefs(useSessionStore())

const avatarSize = computed(() => (props.collapsed ? 'small' : 'normal'))

const { popover, popoverTarget, toggle, isOpen: popoverIsOpen } = usePopover()

const { ticketCreateEnabled } = useTicketCreateView()
</script>

<template>
  <section
    class="flex flex-row items-center justify-between"
    :class="{ 'mx-auto mb-0.5': collapsed }"
  >
    <CommonPopover
      id="user-menu-popover"
      ref="popover"
      :owner="popoverTarget"
      :hide-arrow="collapsed"
      orientation="autoVertical"
      :placement="collapsed ? 'start' : 'arrowStart'"
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
        class="!flex border-gray-900"
        :size="avatarSize"
        personal
      />
    </button>

    <div v-if="!collapsed" class="flex gap-1.5 rounded-md bg-gray-700 p-4">
      <CommonLink v-if="ticketCreateEnabled" link="/tickets/create">
        <CommonIcon
          class="text-blue-800"
          size="small"
          name="plus-square-fill"
        />
      </CommonLink>
    </div>
  </section>
</template>
