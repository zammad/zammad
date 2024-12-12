<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { storeToRefs } from 'pinia'
import { ref } from 'vue'

import { useApplicationStore } from '#shared/stores/application.ts'
import { useSessionStore } from '#shared/stores/session.ts'

import LeftSidebarFooterMenu from '#desktop/components/layout/LayoutSidebar/LeftSidebar/LeftSidebarFooterMenu.vue'
import LeftSidebarHeader from '#desktop/components/layout/LayoutSidebar/LeftSidebar/LeftSidebarHeader.vue'
import LayoutSidebar from '#desktop/components/layout/LayoutSidebar.vue'
import { numberOfPermanentItems } from '#desktop/components/PageNavigation/firstLevelRoutes.ts'
import PageNavigation from '#desktop/components/PageNavigation/PageNavigation.vue'
import UserTaskbarTabs from '#desktop/components/UserTaskbarTabs/UserTaskbarTabs.vue'
import { useResizeGridColumns } from '#desktop/composables/useResizeGridColumns.ts'

const { config } = storeToRefs(useApplicationStore())

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
    class="grid h-full max-h-full overflow-y-clip duration-100"
    :class="{ 'transition-none': noTransition }"
    :style="gridColumns"
  >
    <LayoutSidebar
      id="main-sidebar"
      :name="storageKeyId"
      :aria-label="$t('Main sidebar')"
      :current-width="currentSidebarWidth"
      :max-width="maxSidebarWidth"
      :min-width="minSidebarWidth"
      :classes="{
        collapseButton: 'z-60',
        resizeLine: 'z-60',
      }"
      collapsible
      resizable
      no-scroll
      remember-collapse
      @collapse="collapseSidebar"
      @expand="expandSidebar"
      @resize-horizontal="resizeSidebar"
      @resize-horizontal-start="noTransition = true"
      @resize-horizontal-end="noTransition = false"
      @reset-width="resetSidebarWidth"
    >
      <template #default="{ isCollapsed }">
        <!-- TODO: Switch to `scheme-dark` utility once we upgrade to TW 4. -->
        <div
          class="flex h-full flex-col"
          data-theme="dark"
          style="color-scheme: dark"
        >
          <LeftSidebarHeader class="mb-2" :collapsed="isCollapsed" />
          <PageNavigation :collapsed="isCollapsed" />
          <UserTaskbarTabs :collapsed="isCollapsed" />
          <LeftSidebarFooterMenu :collapsed="isCollapsed" class="mt-auto" />
        </div>
      </template>
    </LayoutSidebar>
    <div id="main-content" class="relative">
      <RouterView #default="{ Component, route: currentRoute }">
        <KeepAlive
          :exclude="['ErrorTab']"
          :max="config.ui_task_mananger_max_task_count"
        >
          <component
            :is="Component"
            v-if="!currentRoute.meta.permanentItem"
            :key="currentRoute.path"
          />
        </KeepAlive>
        <KeepAlive :max="numberOfPermanentItems">
          <component
            :is="Component"
            v-if="currentRoute.meta.permanentItem"
            :key="currentRoute.meta.pageKey || currentRoute.path"
          />
        </KeepAlive>
      </RouterView>
    </div>
  </div>
</template>
