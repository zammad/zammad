<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import LayoutMain from '#desktop/components/layout/LayoutMain.vue'
import LayoutBottomBar from '#desktop/components/layout/LayoutBottomBar.vue'
import CommonBreadcrumb from '#desktop/components/CommonBreadcrumb/CommonBreadcrumb.vue'
import type { BreadcrumbItem } from '#desktop/components/CommonBreadcrumb/types.ts'

interface Props {
  breadcrumbItems: BreadcrumbItem[]
}

const props = defineProps<Props>()
</script>

<template>
  <div class="flex max-h-screen flex-col">
    <LayoutMain class="flex grow flex-col gap-3">
      <CommonBreadcrumb :items="props.breadcrumbItems" />
      <slot />
    </LayoutMain>

    <LayoutBottomBar v-if="$slots.bottomBar">
      <slot name="bottomBar" />
    </LayoutBottomBar>
  </div>
</template>
