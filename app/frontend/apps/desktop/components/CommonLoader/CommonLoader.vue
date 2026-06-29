<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import type { Sizes } from '#shared/components/CommonIcon/types.ts'
import { useDebouncedLoading } from '#shared/composables/useDebouncedLoading.ts'
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

const { debouncedLoading } = useDebouncedLoading({
  isLoading: computed(() => props.loading ?? false),
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
    <div
      v-if="debouncedLoading"
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
    <div v-else-if="loading" v-bind="$attrs" :class="minHeightClass" />
    <CommonAlert v-else-if="error" v-bind="$attrs" variant="danger">
      <!-- eslint-disable vue/no-v-html -->
      <span v-html="markup($t(error))" />
    </CommonAlert>
    <slot v-else />
  </Transition>
</template>
