<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import CommonSkeleton from '#desktop/components/CommonSkeleton/CommonSkeleton.vue'

const props = defineProps<{
  articleCount?: number | null
}>()

const counts = computed(() => Math.min(props.articleCount ?? 25, 25))
</script>

<template>
  <section
    role="feed"
    aria-busy="true"
    class="mx-auto w-full max-w-4xl min-w-xs space-y-10 px-12 py-3 pb-8"
  >
    <template v-for="count in counts" :key="count">
      <!-- customer article: avatar outside right -->
      <article
        v-if="count % 2 === 1"
        class="relative"
        :aria-setsize="counts"
        :aria-posinset="count"
      >
        <CommonSkeleton
          rounded
          class="absolute bottom-0 size-7 ltr:-right-2.5 ltr:translate-x-full rtl:-left-2.5 rtl:-translate-x-full"
        />
        <div
          class="space-y-2 rounded-t-xl bg-blue-200 p-3 ltr:rounded-bl-xl rtl:rounded-br-xl dark:bg-gray-700"
        >
          <div class="flex items-center gap-2">
            <CommonSkeleton alternative-background class="h-3 w-24" />
            <CommonSkeleton alternative-background class="h-3 w-16" />
          </div>
          <CommonSkeleton alternative-background class="h-4 w-full" />
          <CommonSkeleton alternative-background class="h-4 w-5/6" />
          <CommonSkeleton alternative-background class="h-4 w-2/3" />
        </div>
      </article>

      <!-- agent article: avatar outside left -->
      <article v-else class="relative" :aria-setsize="counts" :aria-posinset="count">
        <CommonSkeleton
          rounded
          class="absolute bottom-0 size-7 ltr:-left-2.5 ltr:-translate-x-full rtl:-right-2.5 rtl:translate-x-full"
        />
        <div
          class="space-y-2 rounded-t-xl bg-blue-200 p-3 ltr:rounded-br-xl rtl:rounded-bl-xl dark:bg-gray-700"
        >
          <div class="flex items-center gap-2">
            <CommonSkeleton alternative-background class="h-3 w-20" />
            <CommonSkeleton alternative-background class="h-3 w-16" />
          </div>
          <CommonSkeleton alternative-background class="h-4 w-full" />
          <CommonSkeleton alternative-background class="h-4 w-4/5" />
        </div>
      </article>
    </template>
  </section>
</template>
