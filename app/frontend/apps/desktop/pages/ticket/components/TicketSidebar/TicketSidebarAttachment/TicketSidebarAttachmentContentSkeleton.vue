<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonSkeleton from '#desktop/components/CommonSkeleton/CommonSkeleton.vue'
</script>

<template>
  <div class="flex flex-col rounded-lg bg-blue-200 p-1 dark:bg-gray-700">
    <div v-for="i in 3" :key="i" class="flex w-full items-center gap-2 px-2 py-1">
      <CommonSkeleton alternative-background class="h-9 w-9 shrink-0 rounded" />
      <div class="flex flex-1 flex-col gap-1">
        <CommonSkeleton alternative-background class="h-4 w-36" />
        <CommonSkeleton alternative-background class="h-3 w-16" />
      </div>
    </div>
  </div>
</template>
