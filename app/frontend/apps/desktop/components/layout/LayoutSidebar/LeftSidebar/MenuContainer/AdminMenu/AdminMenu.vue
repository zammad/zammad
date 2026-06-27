<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import CommonActionMenu from '#desktop/components/CommonActionMenu/CommonActionMenu.vue'
import adminItems from '#desktop/components/layout/LayoutSidebar/LeftSidebar/MenuContainer/AdminMenu/plugins/index.ts'
import { SidebarName } from '#desktop/components/layout/types.ts'
import { useSidebarDisplay } from '#desktop/components/layout/useSidebarDisplay.ts'

const { isSidebarCollapsed } = useSidebarDisplay(SidebarName.Primary)

const defaultItem = computed(() => adminItems.find((item) => item.key === 'admin'))
</script>

<template>
  <CommonActionMenu
    class="flex!"
    :actions="adminItems"
    orientation="autoVertical"
    :default-icon="defaultItem?.icon"
    :default-button-variant="defaultItem?.variant"
    :hide-arrow="isSidebarCollapsed"
    :placement="isSidebarCollapsed ? 'start' : 'arrowStart'"
    link-size="small"
    button-size="large"
  />
</template>
