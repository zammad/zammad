<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
interface Props {
  name: string
}

defineProps<Props>()

// `CommonSkeleton` is focusable and carries its own progressbar label, which would add
//   three tab stops and three redundant announcements per uploading file. The bars here are
//   purely decorative instead, and the row as a whole carries the single status label.
const barClasses = 'animate-pulse rounded-md bg-blue-300 dark:bg-gray-800'
</script>

<template>
  <!-- Mirrors the geometry of `CommonFileListItem` so the row does not jump once the upload
    resolves and the real item takes its place. -->
  <div
    data-test-id="file-list-item-skeleton"
    role="status"
    :aria-label="$t('Uploading file: %s', name)"
    class="flex items-center gap-2 rounded-[calc(var(--radius-lg)-var(--spacing))] p-2.5"
  >
    <div :class="barClasses" class="size-9 shrink-0 rounded-[3px]"></div>
    <div class="flex min-w-0 flex-1 flex-col gap-1.5">
      <div :class="barClasses" class="h-3.5 w-3/4"></div>
      <div :class="barClasses" class="h-3 w-1/3"></div>
    </div>
  </div>
</template>
