<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import { useDebouncedLoading } from '#shared/composables/useDebouncedLoading.ts'

import CommonSkeleton from '#desktop/components/CommonSkeleton/CommonSkeleton.vue'

interface Props {
  loading?: boolean
}

const props = defineProps<Props>()

// Debounced like the other popover skeletons: a cached or fast answer would otherwise flash a
//   skeleton for a frame on the way to content that was already there.
const { debouncedLoading } = useDebouncedLoading({
  isLoading: computed(() => props.loading ?? false),
})
</script>

<template>
  <!-- The padding is the skeleton's own rather than something the caller passes in: this root is
       conditional, so the component renders a fragment and cannot inherit a class. Once loaded,
       KnowledgeBaseAnswerPopover brings its own. (TicketPopoverSkeleton has no padding of its own
       because TicketPopover puts it on the section that wraps both states - a variation on the same
       pattern, not a different one.) -->
  <div v-if="loading || debouncedLoading" class="p-3" :class="{ invisible: !debouncedLoading }">
    <!-- Visibility icon and title. -->
    <div class="mb-3 flex items-center gap-1.25">
      <CommonSkeleton :style="{ 'animation-delay': `${0.1}s` }" class="h-4 w-4 shrink-0" rounded />
      <CommonSkeleton :style="{ 'animation-delay': `${0.1}s` }" class="h-5 w-2/3" />
    </div>

    <!-- Body excerpt. -->
    <div class="mb-3 space-y-2">
      <CommonSkeleton :style="{ 'animation-delay': `${0.2}s` }" class="h-4 w-full" />
      <CommonSkeleton :style="{ 'animation-delay': `${0.3}s` }" class="h-4 w-4/5" />
    </div>

    <!-- The attribute grid: a label and a value per row. -->
    <div class="space-y-2">
      <CommonSkeleton :style="{ 'animation-delay': `${0.4}s` }" class="h-4 w-1/4" />
      <CommonSkeleton :style="{ 'animation-delay': `${0.5}s` }" class="h-5 w-1/3" />
      <CommonSkeleton :style="{ 'animation-delay': `${0.6}s` }" class="h-4 w-1/4" />
      <CommonSkeleton :style="{ 'animation-delay': `${0.7}s` }" class="h-5 w-1/5" />
    </div>
  </div>
  <slot v-else />
</template>
