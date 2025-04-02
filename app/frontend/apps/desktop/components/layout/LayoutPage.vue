<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import {
  type MaybeElementRef,
  useCurrentElement,
  type VueInstance,
} from '@vueuse/core'
import { delay } from 'lodash-es'
import { storeToRefs } from 'pinia'
import { ref, useTemplateRef, watch } from 'vue'

import { useTrapTab } from '#shared/composables/useTrapTab.ts'
import { useApplicationStore } from '#shared/stores/application.ts'
import { useSessionStore } from '#shared/stores/session.ts'
import emitter from '#shared/utils/emitter.ts'

import LeftSidebarFooterMenu from '#desktop/components/layout/LayoutSidebar/LeftSidebar/LeftSidebarFooterMenu.vue'
import LeftSidebarHeader from '#desktop/components/layout/LayoutSidebar/LeftSidebar/LeftSidebarHeader.vue'
import LayoutSidebar from '#desktop/components/layout/LayoutSidebar.vue'
import { numberOfPermanentItems } from '#desktop/components/PageNavigation/firstLevelRoutes.ts'
import PageNavigation from '#desktop/components/PageNavigation/PageNavigation.vue'
import QuickSearch from '#desktop/components/Search/QuickSearch/QuickSearch.vue'
import UserTaskbarTabs from '#desktop/components/UserTaskbarTabs/UserTaskbarTabs.vue'
import { useResizeGridColumns } from '#desktop/composables/useResizeGridColumns.ts'

const { config } = storeToRefs(useApplicationStore())

const noTransition = ref(false)

const layoutSidebarInstance = useTemplateRef('layout-sidebar')

const isQuickSearchActive = ref(false)
const quickSearchValue = ref('')

const { deactivateTabTrap, activateTabTrap } = useTrapTab(
  useCurrentElement(
    layoutSidebarInstance as MaybeElementRef<VueInstance> | undefined,
  ),
  true,
)

watch(isQuickSearchActive, (isActive) =>
  isActive ? activateTabTrap() : deactivateTabTrap(),
)

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

const emitSidebarEvent = (wait = 100) => {
  delay(() => {
    emitter.emit('main-sidebar-transition')
  }, wait)
}

const onCollapse = () => {
  collapseSidebar()
  emitSidebarEvent()
}

const onExpand = () => {
  expandSidebar()
  emitSidebarEvent()
}

const onResize = (width: number) => {
  resizeSidebar(width)
  emitSidebarEvent(0)
}

const onResetWidth = () => {
  resetSidebarWidth()
  emitSidebarEvent()
}
</script>

<template>
  <div
    class="grid h-full max-h-full overflow-y-clip duration-100"
    :class="{ 'transition-none': noTransition }"
    :style="gridColumns"
  >
    <LayoutSidebar
      id="main-sidebar"
      ref="layout-sidebar"
      :name="storageKeyId"
      :aria-label="$t('Main sidebar')"
      :current-width="currentSidebarWidth"
      :max-width="maxSidebarWidth"
      :min-width="minSidebarWidth"
      :classes="{
        collapseButton: 'z-60',
        resizeLine: 'z-60',
      }"
      :collapsible="!isQuickSearchActive"
      resizable
      no-scroll
      :no-padding="isQuickSearchActive"
      remember-collapse
      @collapse="onCollapse"
      @expand="onExpand"
      @resize-horizontal="onResize"
      @resize-horizontal-start="noTransition = true"
      @resize-horizontal-end="noTransition = false"
      @reset-width="onResetWidth"
    >
      <template #default="{ isCollapsed }">
        <!-- TODO: Switch to `scheme-dark` utility once we upgrade to TW 4. -->
        <div
          class="flex h-full flex-col"
          data-theme="dark"
          style="color-scheme: dark"
        >
          <LeftSidebarHeader
            v-model:search="quickSearchValue"
            v-model:search-active="isQuickSearchActive"
            class="mb-2"
            :class="{ 'px-3 pt-2.5': isQuickSearchActive }"
            :collapsed="isCollapsed"
          />
          <QuickSearch
            v-show="isQuickSearchActive"
            :search="quickSearchValue"
            :collapsed="isCollapsed"
          />
          <PageNavigation
            v-show="!isQuickSearchActive"
            :collapsed="isCollapsed"
          />
          <UserTaskbarTabs
            v-show="!isQuickSearchActive"
            :collapsed="isCollapsed"
          />
          <LeftSidebarFooterMenu
            v-show="!isQuickSearchActive"
            :collapsed="isCollapsed"
            class="mt-auto"
          />
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
            :key="currentRoute.meta.pageKey || currentRoute.path"
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
