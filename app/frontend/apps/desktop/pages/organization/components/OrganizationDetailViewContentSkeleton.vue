<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonSkeleton from '#desktop/components/CommonSkeleton/CommonSkeleton.vue'
</script>

<template>
  <div class="@container flex size-full flex-col overflow-y-auto">
    <header
      class="sticky top-0 z-20 w-full border-b border-neutral-100 bg-neutral-50/80 px-5.5 py-3 backdrop-blur-2xs dark:border-gray-900 dark:bg-gray-500/80"
    >
      <div class="flex h-6 items-center gap-1.5">
        <CommonSkeleton class="h-3 w-20" />
        <CommonSkeleton class="h-3 w-2" />
        <CommonSkeleton class="h-3 w-32" />
      </div>

      <div class="mx-auto mt-3 flex w-full max-w-278 items-center gap-3">
        <CommonSkeleton rounded class="size-14 shrink-0" />
        <CommonSkeleton class="h-7 w-44" />
        <div class="ms-auto flex items-center gap-1.5">
          <CommonSkeleton class="h-8 w-24" />
          <CommonSkeleton rounded class="size-8" />
        </div>
      </div>
    </header>

    <section class="mx-auto grid w-full max-w-5xl grid-cols-1 gap-6 px-5.5 py-3 @2xl:grid-cols-2">
      <div class="flex flex-col gap-5 self-start">
        <div v-for="i in 4" :key="i" class="flex flex-col gap-1.5">
          <CommonSkeleton class="h-3 w-14" />
          <CommonSkeleton class="h-5 w-48" />
        </div>
      </div>

      <div class="flex flex-col gap-3 rounded-lg bg-blue-200 p-3 dark:bg-gray-500">
        <CommonSkeleton class="h-5 w-40" />
        <div class="flex gap-2">
          <CommonSkeleton class="h-8 w-24" />
          <CommonSkeleton class="h-8 w-28" />
        </div>
        <CommonSkeleton class="h-4 w-24" />
        <div v-for="i in 5" :key="i" class="flex items-center gap-2">
          <CommonSkeleton rounded class="size-5 shrink-0" />
          <div class="flex flex-col gap-1">
            <CommonSkeleton class="h-4 w-36" />
            <CommonSkeleton class="h-3 w-20" />
          </div>
        </div>
      </div>

      <div class="flex flex-col gap-3 @2xl:col-span-2">
        <CommonSkeleton class="h-5 w-36" />
        <CommonSkeleton class="h-52 w-full" />
      </div>
    </section>
  </div>
</template>
