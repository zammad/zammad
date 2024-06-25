<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { onMounted, toRef } from 'vue'

import { useTicketSidebar } from '../../composables/useTicketSidebar.ts'

import TicketSidebarButton from './TicketSidebarButton.vue'

import type { TicketSidebarPlugin } from './plugins/types'
import type { TicketSidebarContext } from '../types.ts'

interface Props {
  sidebar: string
  sidebarPlugin: TicketSidebarPlugin
  context: TicketSidebarContext
  selected: boolean
}

const props = defineProps<Props>()

const { showSidebar } = useTicketSidebar(toRef(props, 'context'))

onMounted(() => {
  // TODO: Move this to proper place after the data query is implemented.
  showSidebar(props.sidebar)
})
</script>

<template>
  <TicketSidebarButton
    :key="sidebar"
    :name="sidebar"
    :label="sidebarPlugin.title"
    :icon="sidebarPlugin.icon"
    :selected="selected"
  />
</template>
