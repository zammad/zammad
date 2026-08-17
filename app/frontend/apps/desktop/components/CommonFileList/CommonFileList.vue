<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts" generic="T extends FileListFile">
import type { FilePreview } from '#shared/utils/files.ts'

import CommonFileListItem from './CommonFileListItem.vue'

import type { FileListFile } from './types.ts'

defineProps<{
  files: T[]
  label?: string
  noRemove?: boolean
}>()

defineEmits<{
  preview: [type: FilePreview, file: T]
  remove: [file: T]
}>()
</script>

<template>
  <div class="@container/file-list rounded-lg bg-blue-200 p-1 dark:bg-gray-700">
    <ul
      :aria-label="label"
      class="grid grid-cols-1 gap-2 @md/file-list:grid-cols-2 @2xl/file-list:grid-cols-3"
    >
      <li v-for="file of files" :key="file.internalId">
        <CommonFileListItem
          :file="file"
          :no-remove="noRemove"
          @preview="$emit('preview', $event, file)"
          @remove="$emit('remove', file)"
        />
      </li>
    </ul>
  </div>
</template>
