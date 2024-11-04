<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import CommonActionMenu from '#desktop/components/CommonActionMenu/CommonActionMenu.vue'
import adminItems from '#desktop/components/layout/LayoutSidebar/LeftSidebar/MenuContainer/AdminMenu/plugins/index.ts'
import { useCollapsedState } from '#desktop/components/layout/LayoutSidebar/LeftSidebar/useCollapsedState.ts'

const { collapsedState } = useCollapsedState()

const defaultItem = computed(() =>
  adminItems.find((item) => item.key === 'admin'),
)
</script>

<template>
  <CommonActionMenu
    class="flex"
    :actions="adminItems"
    orientation="autoVertical"
    :default-icon="defaultItem?.icon"
    :default-button-variant="defaultItem?.variant"
    :hide-arrow="collapsedState"
    :placement="collapsedState ? 'start' : 'arrowStart'"
    link-size="small"
    button-size="large"
  />
</template>
