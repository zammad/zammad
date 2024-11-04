<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import CommonActionMenu from '#desktop/components/CommonActionMenu/CommonActionMenu.vue'
import menuItems from '#desktop/components/layout/LayoutSidebar/LeftSidebar/MenuContainer/AddMenu/plugins/index.ts'
import { useCollapsedState } from '#desktop/components/layout/LayoutSidebar/LeftSidebar/useCollapsedState.ts'

const { collapsedState } = useCollapsedState()

const defaultItem = computed(() =>
  menuItems.find((item) => item.key === 'ticket-create'),
)
</script>

<template>
  <CommonActionMenu
    class="flex"
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
