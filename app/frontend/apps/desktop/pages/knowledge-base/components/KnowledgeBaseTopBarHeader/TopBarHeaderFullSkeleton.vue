<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonSkeleton from '#desktop/components/CommonSkeleton/CommonSkeleton.vue'
</script>

<template>
  <header
    class="grid w-full grid-cols-[1fr_min-content] grid-rows-2 gap-x-2 gap-y-2.5 border-b border-neutral-100 bg-neutral-50/80 px-5.5 py-3 backdrop-blur-2xs dark:border-gray-900 dark:bg-gray-500/80"
  >
    <div class="flex h-6 items-center gap-1.5">
      <CommonSkeleton class="size-3.5 shrink-0" rounded />
      <CommonSkeleton class="h-3 w-24" />
    </div>

    <div role="toolbar" class="flex items-center gap-2.5">
      <CommonSkeleton class="size-6 shrink-0" />
      <CommonSkeleton class="h-6 w-12" />
    </div>

    <div class="col-span-2 mx-auto w-full max-w-[calc(var(--container-7xl)-2.750rem)]">
      <CommonSkeleton class="h-6 w-64" />
    </div>
  </header>
</template>
