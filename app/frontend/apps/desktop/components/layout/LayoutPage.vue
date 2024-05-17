<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { ref } from 'vue'

import { useSessionStore } from '#shared/stores/session.ts'

import LayoutSidebarFooterMenu from '#desktop/components/layout/LayoutSidebar/LayoutSidebarFooterMenu.vue'
import LayoutSidebar from '#desktop/components/layout/LayoutSidebar.vue'
import PageNavigation from '#desktop/components/PageNavigation/PageNavigation.vue'
import { useResizeGridColumns } from '#desktop/composables/useResizeGridColumns.ts'

const noTransition = ref(false)
const { userId } = useSessionStore()
const storageKeyId = `${userId}-left`
const {
  currentSidebarWidth,
  maxSidebarWidth,
  minSidebarWidth,
  gridColumns,
  collapseSidebar,
  resizeSidebar,
  expandSidebar,
  resetSidebarWidth,
} = useResizeGridColumns(storageKeyId)
</script>

<template>
  <div
    class="grid h-full duration-100"
    :class="{ 'transition-none': noTransition }"
    :style="gridColumns"
  >
    <!-- :TODO fix est-lint ltr/rtl right rule to avoid complaining about left id    -->
    <LayoutSidebar
      id="main-sidebar"
      :name="storageKeyId"
      :aria-label="$t('Main sidebar')"
      :current-width="currentSidebarWidth"
      :max-width="maxSidebarWidth"
      :min-width="minSidebarWidth"
      collapsible
      resizable
      @collapse="collapseSidebar"
      @expand="expandSidebar"
      @resize-horizontal="resizeSidebar"
      @resize-horizontal-start="noTransition = true"
      @resize-horizontal-end="noTransition = false"
      @reset-width="resetSidebarWidth"
    >
      <template #default="{ isCollapsed }">
        <PageNavigation :icon-only="isCollapsed" />
        <LayoutSidebarFooterMenu :collapsed="isCollapsed" class="mt-auto" />
      </template>
    </LayoutSidebar>
    <div id="page-main-content" class="relative">
      <RouterView />
    </div>
  </div>
</template>
