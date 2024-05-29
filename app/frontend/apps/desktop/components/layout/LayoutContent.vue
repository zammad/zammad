<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import CommonBreadcrumb from '#desktop/components/CommonBreadcrumb/CommonBreadcrumb.vue'
import type { BreadcrumbItem } from '#desktop/components/CommonBreadcrumb/types.ts'
import CommonHelpText from '#desktop/components/CommonPageHelp/CommonHelpText.vue'
import CommonPageHelp from '#desktop/components/CommonPageHelp/CommonPageHelp.vue'
import LayoutBottomBar from '#desktop/components/layout/LayoutBottomBar.vue'
import LayoutMain from '#desktop/components/layout/LayoutMain.vue'
import { useTransitionConfig } from '#desktop/composables/useTransitionConfig.ts'

import type { ContentWidth } from './types'

export interface Props {
  breadcrumbItems: BreadcrumbItem[]
  width?: ContentWidth
  helpText?: string[] | string
  /**
   * Hides `default slot` content and shows help text if provided
   */
  showInlineHelp?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  width: 'full',
  showInlineHelp: false,
})

const maxWidth = computed(() =>
  props.width === 'narrow' ? '600px' : undefined,
)

const { durations } = useTransitionConfig()
</script>

<template>
  <div class="flex max-h-screen flex-col">
    <LayoutMain>
      <div
        data-test-id="layout-wrapper"
        class="flex grow flex-col gap-3"
        :style="{ maxWidth }"
      >
        <div class="flex items-center justify-between">
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

    <LayoutBottomBar v-if="$slots.bottomBar">
      <slot name="bottomBar" />
    </LayoutBottomBar>
  </div>
</template>
