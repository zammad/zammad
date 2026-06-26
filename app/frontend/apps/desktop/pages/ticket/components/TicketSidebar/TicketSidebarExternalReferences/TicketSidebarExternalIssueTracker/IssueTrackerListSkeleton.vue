<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonSkeleton from '#desktop/components/CommonSkeleton/CommonSkeleton.vue'
</script>

<template>
  <div class="space-y-5">
    <div v-for="i in 2" :key="i" class="flex gap-2">
      <CommonSkeleton rounded class="mt-0.5 size-4 shrink-0" />

      <div class="min-w-0 grow space-y-2.5">
        <div class="flex gap-2">
          <CommonSkeleton class="h-4 grow" />
          <CommonSkeleton class="size-4 shrink-0" />
        </div>

        <div class="flex flex-col gap-0.5">
          <CommonSkeleton class="h-3 w-10" />
          <CommonSkeleton class="h-5 w-16 !rounded-full" />
        </div>

        <div class="flex flex-col gap-0.5">
          <CommonSkeleton class="h-3 w-16" />
          <CommonSkeleton class="h-4 w-24" />
        </div>

        <div v-if="i === 1" class="flex flex-col gap-0.5">
          <CommonSkeleton class="h-3 w-12" />
          <div class="flex gap-1">
            <CommonSkeleton class="h-5 w-14 !rounded-full" />
            <CommonSkeleton class="h-5 w-10 !rounded-full" />
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
