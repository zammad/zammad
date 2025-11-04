<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import CommonActionMenu from '#desktop/components/CommonActionMenu/CommonActionMenu.vue'
import menuItems from '#desktop/components/layout/LayoutSidebar/LeftSidebar/MenuContainer/AddMenu/plugins/index.ts'
import { useCollapsedState } from '#desktop/components/layout/LayoutSidebar/LeftSidebar/useCollapsedState.ts'

const { collapsedState } = useCollapsedState()

const defaultItem = computed(() => menuItems.find((item) => item.key === 'ticket-create'))
</script>

<template>
  <CommonActionMenu
    :class="{
      'p-2 rounded-md hover:outline hover:outline-blue-900! has-focus-visible:outline has-focus-visible:outline-offset-0! has-focus-visible:outline-blue-800! has-focus-visible:*:outline-none':
        menuItems.length === 1,
    }"
    orientation="autoVertical"
    :hide-arrow="collapsedState"
    :default-icon="defaultItem?.icon"
    :default-button-variant="defaultItem?.variant"
    :placement="collapsedState ? 'start' : 'arrowStart'"
    link-size="small"
    button-size="large"
    :actions="menuItems"
  />
</template>
