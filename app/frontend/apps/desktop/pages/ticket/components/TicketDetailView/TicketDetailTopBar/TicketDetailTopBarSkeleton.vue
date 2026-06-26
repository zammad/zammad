<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonSkeleton from '#desktop/components/CommonSkeleton/CommonSkeleton.vue'
</script>

<template>
  <header
    class="grid w-full grid-cols-2 gap-y-2.5 border-b border-neutral-100 bg-neutral-50 px-5.5 py-3 dark:border-gray-900 dark:bg-gray-500"
  >
    <div class="flex items-center gap-1.5">
      <CommonSkeleton class="h-3 w-12" />
      <CommonSkeleton class="h-3 w-3" />
      <CommonSkeleton class="h-3 w-20" />
    </div>

    <div class="justify-self-end">
      <CommonSkeleton class="h-7 w-28" />
    </div>

    <div class="col-span-2 grid grid-cols-[1fr_minmax(0,66rem)_1fr] gap-4 px-6">
      <div class="flex flex-col gap-1.5 justify-self-end">
        <CommonSkeleton rounded class="size-9 shrink-0" />
      </div>

      <div class="flex flex-col gap-2 pb-3.5">
        <div class="flex items-center gap-2">
          <CommonSkeleton class="h-3.5 w-24" />
          <CommonSkeleton class="h-3.5 w-32" />
        </div>
        <CommonSkeleton class="h-7 w-3/4" />
        <div class="flex gap-1.5">
          <CommonSkeleton rounded class="h-5 w-16" />
          <CommonSkeleton rounded class="h-5 w-20" />
          <CommonSkeleton rounded class="h-5 w-14" />
        </div>
      </div>
    </div>
  </header>
</template>
