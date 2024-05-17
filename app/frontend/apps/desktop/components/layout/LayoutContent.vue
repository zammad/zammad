<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import CommonBreadcrumb from '#desktop/components/CommonBreadcrumb/CommonBreadcrumb.vue'
import type { BreadcrumbItem } from '#desktop/components/CommonBreadcrumb/types.ts'
import LayoutBottomBar from '#desktop/components/layout/LayoutBottomBar.vue'
import LayoutMain from '#desktop/components/layout/LayoutMain.vue'

import type { ContentWidth } from './types'

interface Props {
  width?: ContentWidth
  breadcrumbItems: BreadcrumbItem[]
}

const props = withDefaults(defineProps<Props>(), {
  width: 'full',
})

const maxWidth = computed(() =>
  props.width === 'narrow' ? '600px' : undefined,
)
</script>

<template>
  <div class="flex max-h-screen flex-col">
    <LayoutMain>
      <div class="flex grow flex-col gap-3" :style="{ maxWidth }">
        <div class="flex items-center justify-between">
          <CommonBreadcrumb :items="breadcrumbItems" />
          <slot name="headerRight" />
        </div>
        <slot />
      </div>
    </LayoutMain>

    <LayoutBottomBar v-if="$slots.bottomBar">
      <slot name="bottomBar" />
    </LayoutBottomBar>
  </div>
</template>
