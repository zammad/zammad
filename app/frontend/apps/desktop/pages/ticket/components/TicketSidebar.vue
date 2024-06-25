<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { toRef } from 'vue'

import { useTicketSidebar } from '../composables/useTicketSidebar.ts'

import type { TicketSidebarContext } from './types.ts'

interface Props {
  context: TicketSidebarContext
  isCollapsed: boolean
}

const props = defineProps<Props>()

const {
  activeSidebar,
  activeSidebarPlugin,
  availableSidebarPlugins,
  shownSidebars,
  switchSidebar,
} = useTicketSidebar(toRef(props, 'context'))
</script>

<template>
  <div class="flex h-full justify-end">
    <div v-if="!isCollapsed" class="grow">
      <component
        :is="activeSidebarPlugin?.contentComponent"
        :context="context"
      />
    </div>
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
        @click="switchSidebar"
      />
    </div>
  </div>
</template>
