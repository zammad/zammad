<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import type { Sizes } from '#shared/components/CommonIcon/types.ts'
import { markup } from '#shared/utils/markup.ts'

import CommonSkeleton from '#desktop/components/CommonSkeleton/CommonSkeleton.vue'
import { useTransitionConfig } from '#desktop/composables/useTransitionConfig.ts'

interface Props {
  loading?: boolean
  error?: string | null
  size?: Sizes
  noTransition?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  size: 'medium',
  noTransition: true, // TODO: disable it for now by default, until we have a clear picture for that.
})

const minHeightClass = computed(() => {
  switch (props.size) {
    case 'xs':
      return 'min-h-4'
    case 'tiny':
      return 'min-h-6'
    case 'small':
      return 'min-h-8'
    case 'base':
      return 'min-h-10'
    case 'large':
      return 'min-h-20'
    case 'xl':
      return 'min-h-36'
    case 'medium':
    default:
      return 'min-h-12'
  }
})

const { transitions } = useTransitionConfig()
</script>

<script lang="ts">
export default {
  inheritAttrs: false,
}
</script>

<template>
  <Transition :name="noTransition ? undefined : transitions.fade" mode="out-in">
    <!-- The skeleton stands there for exactly as long as the load runs. It used to be held back
         by a 300ms debounce so a fast load would not flash one - but the only thing that could be
         rendered meanwhile was an empty spacer, which flashed for the very same window and worse:
         an unlabelled box of a fixed height, so the content collapsed to it and grew back again.
         A skeleton is the same window with the shape of what it stands in for. -->
    <div
      v-if="loading"
      v-bind="$attrs"
      class="flex flex-col gap-4"
      :class="minHeightClass"
      role="status"
    >
      <slot name="skeleton">
        <CommonSkeleton
          v-for="i in 3"
          :key="i"
          :style="{ 'animation-delay': `${i * 0.1}s` }"
          class="h-4 w-full"
        />
      </slot>
    </div>
    <CommonAlert v-else-if="error" v-bind="$attrs" variant="danger">
      <!-- eslint-disable vue/no-v-html -->
      <span v-html="markup($t(error))" />
    </CommonAlert>
    <slot v-else />
  </Transition>
</template>
