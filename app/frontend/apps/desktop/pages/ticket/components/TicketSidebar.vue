<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CollapseButton from '#desktop/components/CollapseButton/CollapseButton.vue'
import { SidebarName, useSidebarDisplay } from '#desktop/components/layout/useSidebarDisplay.ts'

import { useTicketSidebar } from '../composables/useTicketSidebar.ts'

import type { TicketSidebarContext } from '../types/sidebar.ts'

interface Props {
  context: TicketSidebarContext
}

defineProps<Props>()

const { isSidebarCollapsed, toggleSidebar } = useSidebarDisplay(SidebarName.TicketContent)

const {
  activeSidebar,
  availableSidebarPlugins,
  shownSidebars,
  showSidebar,
  hideSidebar,
  switchSidebar,
} = useTicketSidebar()

const maybeToggleAndSwitchSidebar = (newSidebar: string) => {
  if (isSidebarCollapsed.value) toggleSidebar()

  switchSidebar(newSidebar)
}
</script>

<template>
  <div class="flex h-full justify-end">
    <div v-show="!isSidebarCollapsed" id="ticketSidebar" class="flex grow flex-col" />
    <div
      class="flex flex-col items-center gap-2.5 border-neutral-100 px-2.5 py-3 transition-[border] dark:border-gray-900"
      :class="{ 'border-s': !isSidebarCollapsed }"
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

      <CollapseButton
        class="mt-auto lg:hidden"
        owner-id="content-sidebar"
        visible
        no-padded
        size="large"
        variant="tertiary-gray"
        inverse
        :collapsed="isSidebarCollapsed"
        :collapse-label="$t('Collapse sidebar')"
        :expand-label="$t('Expand sidebar')"
        @toggle-collapse="toggleSidebar"
      />
    </div>
  </div>
</template>
