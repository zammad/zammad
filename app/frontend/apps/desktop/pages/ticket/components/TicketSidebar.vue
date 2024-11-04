<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useTicketSidebar } from '../composables/useTicketSidebar.ts'

import type { TicketSidebarContext } from '../types/sidebar.ts'

interface Props {
  context: TicketSidebarContext
  isCollapsed: boolean
  toggleCollapse: () => void
}

const props = defineProps<Props>()

const {
  activeSidebar,
  availableSidebarPlugins,
  shownSidebars,
  showSidebar,
  hideSidebar,
  switchSidebar,
} = useTicketSidebar()

const maybeToggleAndSwitchSidebar = (newSidebar: string) => {
  if (props.isCollapsed) props.toggleCollapse()
  switchSidebar(newSidebar)
}
</script>

<template>
  <div class="flex h-full justify-end">
    <div v-show="!isCollapsed" id="ticketSidebar" class="flex grow flex-col" />
    <div
      class="flex flex-col items-center gap-2.5 border-neutral-100 px-2.5 py-3 transition-[border] dark:border-gray-900"
      :class="{ 'border-s': !isCollapsed }"
    >
      <component
        :is="sidebarPlugin.component"
        v-for="(sidebarPlugin, sidebar) of availableSidebarPlugins"
        v-show="shownSidebars[sidebar]"
        :key="sidebar"
        :selected="activeSidebar === sidebar"
        :sidebar="sidebar"
        :sidebar-plugin="sidebarPlugin"
        :context="context"
        @click="maybeToggleAndSwitchSidebar"
        @show="showSidebar(sidebar as string)"
        @hide="hideSidebar(sidebar as string)"
      />
    </div>
  </div>
</template>
