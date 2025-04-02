<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, ref } from 'vue'

import { useTransitionConfig } from '#shared/composables/useTransitionConfig.ts'
import { useSessionStore } from '#shared/stores/session.ts'

import CommonBreadcrumb from '#desktop/components/CommonBreadcrumb/CommonBreadcrumb.vue'
import type { BreadcrumbItem } from '#desktop/components/CommonBreadcrumb/types.ts'
import CommonHelpText from '#desktop/components/CommonPageHelp/CommonHelpText.vue'
import CommonPageHelp from '#desktop/components/CommonPageHelp/CommonPageHelp.vue'
import LayoutBottomBar from '#desktop/components/layout/LayoutBottomBar.vue'
import LayoutMain from '#desktop/components/layout/LayoutMain.vue'
import LayoutSidebar from '#desktop/components/layout/LayoutSidebar.vue'
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
}

const props = withDefaults(defineProps<Props>(), {
  name: 'content',
  backgroundVariant: 'tertiary',
  width: 'full',
  showInlineHelp: false,
  contentAlignment: 'start',
})

const maxWidth = computed(() =>
  props.width === 'narrow' ? '600px' : undefined,
)

const contentAlignmentClass = computed(() => {
  return props.contentAlignment === 'center' ? 'items-center' : ''
})

const noTransition = ref(false)

const { userId } = useSessionStore()

const storageKeyId = `${userId}-${props.name}`

const {
  currentSidebarWidth,
  maxSidebarWidth,
  minSidebarWidth,
  gridColumns,
  collapseSidebar,
  expandSidebar,
  resizeSidebar,
  resetSidebarWidth,
} = useResizeGridColumns(storageKeyId, SidebarPosition.End)

const { durations } = useTransitionConfig()
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
          <div
            v-if="breadcrumbItems"
            data-test-id="wrapper-breadcrumb"
            class="flex min-h-13 items-center justify-between"
            :class="{ 'px-4 pt-4': contentPadding }"
          >
            <CommonBreadcrumb :items="breadcrumbItems" />
            <div
              v-if="$slots.headerRight || helpText || $slots.helpPage"
              class="flex gap-4 ltr:text-left rtl:text-right"
            >
              <CommonPageHelp
                v-if="!showInlineHelp && (helpText || $slots.helpPage)"
              >
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
        #default="{ isCollapsed, toggleCollapse }"
        :name="storageKeyId"
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
        @collapse="collapseSidebar"
        @expand="expandSidebar"
        @resize-horizontal="resizeSidebar"
        @resize-horizontal-start="noTransition = true"
        @resize-horizontal-end="noTransition = false"
        @reset-width="resetSidebarWidth"
      >
        <slot name="sideBar" v-bind="{ isCollapsed, toggleCollapse }" />
      </LayoutSidebar>
    </div>

    <LayoutBottomBar v-if="$slots.bottomBar">
      <slot name="bottomBar" />
    </LayoutBottomBar>
  </div>
</template>
