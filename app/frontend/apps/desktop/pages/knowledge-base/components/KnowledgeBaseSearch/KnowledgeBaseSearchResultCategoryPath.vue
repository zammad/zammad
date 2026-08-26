<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useLocaleStore } from '#shared/stores/locale.ts'

defineProps<{
  categoryPath: { id: string; title?: string | null }[]
}>()

const locale = useLocaleStore()
</script>

<template>
  <!-- Each segment truncates on its own via line-clamp-1 (like CommonBreadcrumb), so a long path
       still shows its full shape instead of the whole line being cut off after the first segment
       or two; a truncated segment reveals its full title as a tooltip on hover. -->
  <div
    v-if="categoryPath.length"
    class="flex min-w-0 items-center gap-1 text-xs leading-snug text-stone-200 dark:text-neutral-500"
  >
    <template v-for="(segment, index) in categoryPath" :key="segment.id">
      <CommonIcon
        v-if="index"
        class="size-2! shrink-0"
        size="xs"
        :name="locale.localeData?.dir === 'rtl' ? 'chevron-left' : 'chevron-right'"
      />
      <span v-tooltip.truncate.supportive="segment.title" class="line-clamp-1 min-w-0 shrink">{{
        segment.title
      }}</span>
    </template>
  </div>
</template>
