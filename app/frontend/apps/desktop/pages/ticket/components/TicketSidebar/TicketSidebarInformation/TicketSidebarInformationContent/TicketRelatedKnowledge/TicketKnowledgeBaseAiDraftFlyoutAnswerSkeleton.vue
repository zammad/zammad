<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script lang="ts" setup>
import CommonSkeleton from '#desktop/components/CommonSkeleton/CommonSkeleton.vue'

interface Props {
  label?: string
}

defineProps<Props>()
</script>

<template>
  <li class="space-y-1.5 py-2.5 first:pt-0 last:pb-0">
    <div class="flex items-center gap-1.5">
      <CommonSkeleton class="size-4 shrink-0 rounded-md" alternative-background />
      <CommonSkeleton class="h-3.5 grow rounded-md" :label="label" alternative-background />
      <CommonSkeleton class="h-3.5 w-8 shrink-0 rounded-md" alternative-background />
    </div>

    <CommonSkeleton class="h-3.5 w-full rounded-md" alternative-background />

    <div class="grid grid-cols-2 content-start gap-3">
      <div v-for="index in 3" :key="index" class="flex flex-col gap-0.5">
        <CommonSkeleton class="h-3 w-14 rounded-md" alternative-background />
        <CommonSkeleton class="h-3.5 w-20 rounded-md" alternative-background />
      </div>
    </div>
  </li>
</template>
