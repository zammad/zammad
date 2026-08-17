<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonSkeleton from '#desktop/components/CommonSkeleton/CommonSkeleton.vue'

// Roughly the shape of an answer body: two paragraphs of a few lines each, with the
//   last line of every paragraph running short.
const paragraphs = [
  ['w-full', 'w-full', 'w-2/3'],
  ['w-full', 'w-5/6', 'w-1/2'],
]
</script>

<template>
  <div class="flex w-full flex-col gap-6">
    <div v-for="(lines, index) in paragraphs" :key="index" class="flex flex-col gap-2.5">
      <CommonSkeleton
        v-for="(width, lineIndex) in lines"
        :key="lineIndex"
        class="h-3.5"
        :class="width"
      />
    </div>
  </div>
</template>
