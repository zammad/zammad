<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, onBeforeMount, ref, watch } from 'vue'

import emitter from '#shared/utils/emitter.ts'

import { useTransitionConfig } from '#desktop//composables/useTransitionConfig.ts'
import CommonBreadcrumb from '#desktop/components/CommonBreadcrumb/CommonBreadcrumb.vue'
import type { BreadcrumbItem } from '#desktop/components/CommonBreadcrumb/types.ts'
import CommonHelpText from '#desktop/components/CommonPageHelp/CommonHelpText.vue'
import CommonPageHelp from '#desktop/components/CommonPageHelp/CommonPageHelp.vue'
import CommonNavigationTabs from '#desktop/components/CommonTabs/CommonNavigationTabs/CommonNavigationTabs.vue'
import type { NavigationTab } from '#desktop/components/CommonTabs/types.ts'
import LayoutBottomBar from '#desktop/components/layout/LayoutBottomBar.vue'
import LayoutMain from '#desktop/components/layout/LayoutMain.vue'
import LayoutSidebar from '#desktop/components/layout/LayoutSidebar.vue'
import { SidebarName, useSidebarDisplay } from '#desktop/components/layout/useSidebarDisplay.ts'
import { useAppBreakpoints } from '#desktop/composables/responsiveness/useAppBreakpoints.ts'
import { useResizeGridColumns } from '#desktop/composables/useResizeGridColumns.ts'

import {
  SidebarPosition,
  type BackgroundVariant,
  type ContentAlignment,
  type ContentWidth,
} from './types.ts'

export interface Props {
  name?: string
  breadcrumbItems?: BreadcrumbItem[]
  width?: ContentWidth
  backgroundVariant?: BackgroundVariant
  contentAlignment?: ContentAlignment
  helpText?: string[] | string
  /**
   * Hides `default slot` content and shows help text if provided
   */
  showInlineHelp?: boolean
  showSidebar?: boolean
  noPadding?: boolean
  /**
   * Removes padding from main container
   * Applies padding to breadcrumb container
   * ⚠️ Set manually the padding to the default slot container p-4
   */
  contentPadding?: boolean
  /**
   * Disables the vertical scroll on the main element
   */
  noScrollable?: boolean
  tabs?: NavigationTab[]
  activeTab?: NavigationTab['key']
}

const props = withDefaults(defineProps<Props>(), {
  name: 'content',
  backgroundVariant: 'tertiary',
  width: 'full',
  showInlineHelp: false,
  contentAlignment: 'start',
  activeTab: '',
})

const maxWidth = computed(() => (props.width === 'narrow' ? '600px' : undefined))

const contentAlignmentClass = computed(() => {
  return props.contentAlignment === 'center' ? 'items-center' : ''
})

const noTransition = ref(false)

const {
  currentSidebarWidth,
  maxSidebarWidth,
  minSidebarWidth,
  gridColumns,
  resizeSidebar,
  resetSidebarWidth,
} = useResizeGridColumns(SidebarName.TicketContent, SidebarPosition.End)

const { durations } = useTransitionConfig()

const { isSmallScreen } = useAppBreakpoints()
// Needed to make the breakpoint detection work within the layout, which is relevant for the sidebar display behavior
const { isSidebarCollapsed: isPrimaryNavSidebarCollapsed } = useSidebarDisplay(SidebarName.Primary)

const { isSidebarCollapsed: isContentSidebarCollapsed, toggleSidebar: toggleContentSidebar } =
  useSidebarDisplay(SidebarName.TicketContent)

// When the primary nav expands on a small screen (<1024px), collapse the content sidebar.
watch(isPrimaryNavSidebarCollapsed, (isCollapsed) => {
  if (!isSmallScreen.value || isCollapsed) return

  toggleContentSidebar(true)
})

watch(isSmallScreen, (smallScreen) => {
  if (!smallScreen) return

  if (!isContentSidebarCollapsed.value) toggleContentSidebar(true)
})

onBeforeMount(() => {
  // When the screen shrinks into the small viewport(<1024px) and both sidebars are open, close this one.
  if (isSmallScreen.value) toggleContentSidebar(true)
})
</script>

<template>
  <div class="flex h-full max-h-screen flex-col">
    <div
      class="grid h-full duration-100"
      :class="{
        'transition-none': noTransition,
        'max-h-[calc(100%-3.5rem)]': $slots.bottomBar,
        'max-h-screen': !$slots.bottomBar,
      }"
      :style="$slots.sideBar && showSidebar ? gridColumns : undefined"
    >
      <LayoutMain
        ref="layout-main"
        :no-padding="noPadding || contentPadding"
        :no-scrollable="noScrollable"
        :background-variant="backgroundVariant"
      >
        <div
          data-test-id="layout-wrapper"
          class="flex h-full grow flex-col gap-3"
          :class="contentAlignmentClass"
          :style="{ maxWidth }"
        >
          <!-- mx-4, 2rem because of horizontal margin 1rem * 2 -> Parent size minus margin -->
          <CommonNavigationTabs
            v-if="tabs?.length"
            class="lg:hidden"
            :class="[width !== 'narrow' ? 'mx-4 mt-4 max-w-[calc(100%-2rem)]' : 'max-w-full']"
            :model-value="activeTab"
            :tabs="tabs"
          />

          <div
            v-if="breadcrumbItems"
            data-test-id="wrapper-breadcrumb"
            class="flex min-h-13 items-center justify-between"
            :class="{ 'px-4 pt-4': contentPadding, 'pt-0!': tabs?.length }"
          >
            <CommonBreadcrumb :items="breadcrumbItems" />
            <div
              v-if="$slots.headerRight || helpText || $slots.helpPage"
              class="flex gap-4 ltr:text-left rtl:text-right"
            >
              <CommonPageHelp v-if="!showInlineHelp && (helpText || $slots.helpPage)">
                <slot name="helpPage">
                  <CommonHelpText :help-text="helpText" />
                </slot>
              </CommonPageHelp>

              <slot name="headerRight" />
            </div>
          </div>

          <Transition :duration="durations.normal" name="fade" mode="out-in">
            <slot v-if="!showInlineHelp" />
            <slot v-else name="helpPage">
              <CommonHelpText :help-text="helpText" />
            </slot>
          </Transition>
        </div>
      </LayoutMain>

      <LayoutSidebar
        v-if="$slots.sideBar"
        v-show="showSidebar"
        id="content-sidebar"
        :name="SidebarName.TicketContent"
        :position="SidebarPosition.End"
        :aria-label="$t('Content sidebar')"
        collapsible
        resizable
        :current-width="currentSidebarWidth"
        :max-width="maxSidebarWidth"
        :min-width="minSidebarWidth"
        no-padding
        no-scroll
        class="bg-neutral-50! dark:bg-gray-500!"
        :class="{
          'max-h-[calc(100dvh-3.5rem)]!': $slots.bottomBar,
        }"
        @collapse="emitter.emit('resize-layout')"
        @expand="emitter.emit('resize-layout')"
        @resize-horizontal="resizeSidebar"
        @resize-horizontal-start="noTransition = true"
        @resize-horizontal-end="noTransition = false"
        @reset-width="resetSidebarWidth"
      >
        <slot name="sideBar" />
      </LayoutSidebar>
    </div>

    <LayoutBottomBar v-if="$slots.bottomBar">
      <slot name="bottomBar" />
    </LayoutBottomBar>
  </div>
</template>
