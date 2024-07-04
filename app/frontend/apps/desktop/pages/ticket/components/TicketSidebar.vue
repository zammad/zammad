<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { toRef } from 'vue'

import CommonLoader from '#desktop/components/CommonLoader/CommonLoader.vue'

import { useTicketSidebar } from '../composables/useTicketSidebar.ts'

import type { TicketSidebarContext } from './types.ts'

interface Props {
  context: TicketSidebarContext
  isCollapsed: boolean
  toggleCollapse: () => void
}

const props = defineProps<Props>()

const {
  activeSidebar,
  activeSidebarPlugin,
  availableSidebarPlugins,
  shownSidebars,
  showSidebar,
  hideSidebar,
  switchSidebar,
} = useTicketSidebar(toRef(props, 'context'))

const maybeToggleAndSwitchSidebar = (newSidebar: string) => {
  if (props.isCollapsed) props.toggleCollapse()
  switchSidebar(newSidebar)
}
</script>

<template>
  <div class="flex h-full justify-end">
    <CommonLoader
      class="mx-auto self-center"
      :loading="!activeSidebarPlugin?.contentComponent"
    >
      <div v-if="!isCollapsed" class="flex grow flex-col">
        <component
          :is="activeSidebarPlugin?.contentComponent"
          :context="context"
        />
      </div>
    </CommonLoader>
    <div
      class="flex w-12 flex-col items-center gap-2.5 border-neutral-100 px-2.5 py-3 transition-[border] dark:border-gray-900"
      :class="{ 'border-s': !isCollapsed }"
    >
      <component
        :is="sidebarPlugin.buttonComponent"
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
