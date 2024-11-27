<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
/* eslint-disable vue/no-v-html */

import { computed } from 'vue'

import type { Sizes } from '#shared/components/CommonIcon/types.ts'
import { markup } from '#shared/utils/markup.ts'

interface Props {
  loading?: boolean
  error?: string | null
  size?: Sizes
  noTransition?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  size: 'medium',
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
</script>

<script lang="ts">
export default {
  inheritAttrs: false,
}
</script>

<template>
  <Transition :name="noTransition ? 'none' : 'fade'" mode="out-in">
    <div
      v-if="loading"
      v-bind="$attrs"
      class="flex items-center justify-center"
      :class="minHeightClass"
      role="status"
    >
      <CommonIcon
        class="fill-yellow-300"
        name="spinner"
        :size="size"
        animation="spin"
        :label="__('Loading…')"
      />
    </div>
    <CommonAlert v-else-if="error" v-bind="$attrs" variant="danger">
      <span v-html="markup($t(error))" />
    </CommonAlert>
    <slot v-else />
  </Transition>
</template>
