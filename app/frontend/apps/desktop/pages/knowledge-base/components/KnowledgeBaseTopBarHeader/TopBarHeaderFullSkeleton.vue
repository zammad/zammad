<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import CommonSkeleton from '#desktop/components/CommonSkeleton/CommonSkeleton.vue'

import { HEADER_CONTENT_OUTER_CLASSES, HEADER_CONTENT_WIDTH_CLASSES } from './headerClasses.ts'
import { type HeaderContentWidth } from './types.ts'

// Mirrors the detail row of the answer header, so the skeleton has the same
//   height as the header it stands in for.
const props = withDefaults(
  defineProps<{
    withDetails?: boolean
    contentWidth?: HeaderContentWidth
  }>(),
  {
    contentWidth: 'wide',
  },
)

const contentWidthClass = computed(() => HEADER_CONTENT_WIDTH_CLASSES[props.contentWidth])
const contentOuterClass = computed(() => HEADER_CONTENT_OUTER_CLASSES[props.contentWidth])
</script>

<template>
  <header
    class="grid w-full grid-cols-[1fr_min-content] gap-x-2 gap-y-2.5 border-b border-neutral-100 bg-neutral-50/80 px-5.5 py-3 backdrop-blur-2xs dark:border-gray-900 dark:bg-gray-500/80"
  >
    <div class="flex h-6 items-center gap-1.5">
      <CommonSkeleton class="size-3.5 shrink-0" rounded />
      <CommonSkeleton class="h-3 w-24" />
    </div>

    <div role="toolbar" class="flex items-center gap-2.5">
      <CommonSkeleton class="size-6 shrink-0" />
      <CommonSkeleton class="h-6 w-12" />
    </div>

    <div class="col-span-2" :class="contentOuterClass">
      <div class="mx-auto w-full" :class="contentWidthClass">
        <CommonSkeleton class="h-6 w-64" />
      </div>
    </div>

    <div v-if="withDetails" class="col-span-2" :class="contentOuterClass">
      <div class="mx-auto flex w-full gap-2.5" :class="contentWidthClass">
        <CommonSkeleton class="h-7 w-24" rounded />
        <CommonSkeleton class="h-7 w-56" rounded />
      </div>
    </div>
  </header>
</template>
