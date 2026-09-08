<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonDivider from '#desktop/components/CommonDivider/CommonDivider.vue'
import CommonSkeleton from '#desktop/components/CommonSkeleton/CommonSkeleton.vue'

import {
  CATEGORY_GRID_CLASSES,
  CATEGORY_GRID_REVEAL,
} from '../../utils/knowledgeBaseCategoryGrid.ts'

interface Props {
  count: number
}

const props = defineProps<Props>()
</script>

<!-- Stands in for the category grid only, inside the same section the loaded grid uses —
     so it brings no layout of its own. -->
<template>
  <!-- w-full: the loader centers its skeleton in a flex column, where a bare grid would
       otherwise shrink to its content width. -->
  <ol :class="CATEGORY_GRID_CLASSES" class="w-full">
    <li
      v-for="i in props.count"
      :key="i"
      class="flex min-h-42 flex-col items-center justify-center rounded-xl bg-blue-200 px-3 pt-6 dark:bg-gray-500"
      :class="CATEGORY_GRID_REVEAL[i as keyof typeof CATEGORY_GRID_REVEAL]"
    >
      <div class="flex w-full flex-col items-center gap-3">
        <CommonSkeleton class="size-8" rounded alternative-background />
        <div class="mb-3 flex min-h-11 w-full items-center justify-center">
          <CommonSkeleton
            :style="{ 'animation-delay': '0.1s' }"
            class="h-3.5 w-2/3"
            alternative-background
          />
        </div>
      </div>

      <CommonDivider />

      <div class="flex w-full items-center justify-between py-2">
        <div class="flex items-center gap-3">
          <div class="flex gap-1">
            <CommonSkeleton
              :style="{ 'animation-delay': '0.3s' }"
              class="size-5"
              rounded
              alternative-background
            />
            <CommonSkeleton
              :style="{ 'animation-delay': '0.3s' }"
              class="size-5"
              rounded
              alternative-background
            />
          </div>
        </div>
      </div>
    </li>
  </ol>
</template>
