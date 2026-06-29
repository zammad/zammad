<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import CommonSkeleton from '#desktop/components/CommonSkeleton/CommonSkeleton.vue'
import { MINIMUM_COLUMN_WIDTH } from '#desktop/components/CommonTable/types.ts'

interface Props {
  rows?: number
  columns?: number
  hasBulkAction?: boolean
  hasActions?: boolean
  columnWidths?: number[]
  /**
   * Is used when you have a table with data present and want to show more
   * the new loading data
   */
  loadMore?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  rows: 5,
  columns: 5,
})

const defaultColumnWidthsPx = [96, 144, 112, 192, 128, 80, 96]

const getColumnStyle = (index: number): { width: string } => {
  const measured = props.columnWidths?.[index]
  const px = Math.max(
    measured && measured > 0
      ? measured
      : defaultColumnWidthsPx[index % defaultColumnWidthsPx.length],
    MINIMUM_COLUMN_WIDTH,
  )
  return { width: `${px}px` }
}

const totalColumns = computed(
  () => props.columns + (props.hasBulkAction ? 1 : 0) + (props.hasActions ? 1 : 0),
)
</script>

<template>
  <table>
    <thead class="sticky top-0 z-10 bg-neutral-50 dark:bg-gray-500">
      <tr v-if="!loadMore">
        <th v-if="hasBulkAction" class="w-6">
          <div class="flex items-center px-3 py-2.5 ltr:pr-0 rtl:pl-0">
            <CommonSkeleton class="size-4" />
          </div>
        </th>
        <th v-for="n in columns" :key="n" :style="getColumnStyle(n - 1)">
          <div class="flex items-center p-2.5">
            <CommonSkeleton class="h-2 w-full max-w-16" />
          </div>
        </th>
        <th v-if="hasActions" class="w-10">
          <div class="flex items-center p-2.5">
            <CommonSkeleton class="size-4" />
          </div>
        </th>
      </tr>
    </thead>

    <tbody>
      <tr
        v-for="n in rows"
        :key="n"
        class="odd:bg-blue-200 even:invisible odd:dark:bg-gray-700"
        :style="{ clipPath: 'xywh(0 0 100% 100% round 0.375rem)' }"
      >
        <td :colspan="totalColumns">
          <div class="h-10 px-3 py-2.5">
            <CommonSkeleton class="size-full" />
          </div>
        </td>
      </tr>
    </tbody>
  </table>
</template>
