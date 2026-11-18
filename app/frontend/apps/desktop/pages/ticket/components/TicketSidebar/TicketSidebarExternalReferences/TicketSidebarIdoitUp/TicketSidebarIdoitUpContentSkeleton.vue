<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonSkeleton from '#desktop/components/CommonSkeleton/CommonSkeleton.vue'
</script>

<template>
  <div class="space-y-6">
    <div v-for="i in 2" :key="i" class="space-y-2">
      <div class="flex gap-2">
        <CommonSkeleton class="h-4 grow" />
        <CommonSkeleton class="size-4 shrink-0" />
      </div>

      <div v-for="j in 3" :key="j" class="flex flex-col gap-0.5">
        <CommonSkeleton class="h-3 w-10" />
        <CommonSkeleton class="h-4 w-20" />
      </div>
    </div>
  </div>
</template>
