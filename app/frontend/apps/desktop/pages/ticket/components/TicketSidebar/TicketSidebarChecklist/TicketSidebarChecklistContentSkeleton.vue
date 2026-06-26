<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonSkeleton from '#desktop/components/CommonSkeleton/CommonSkeleton.vue'
</script>

<template>
  <div class="grid grid-cols-2 gap-x-2">
    <CommonSkeleton class="col-span-2 mb-3 h-5 w-40" />

    <ul class="col-span-2 mb-2 space-y-2">
      <li
        v-for="i in 3"
        :key="i"
        class="flex min-h-10 items-center gap-2 rounded-lg bg-blue-200 p-2 dark:bg-gray-700"
      >
        <CommonSkeleton alternative-background class="size-4 shrink-0" />
        <CommonSkeleton alternative-background class="h-4 grow" />
        <CommonSkeleton alternative-background class="size-6 shrink-0" />
      </li>
    </ul>

    <CommonSkeleton class="col-start-2 h-8 w-8 justify-self-end" />
  </div>
</template>
