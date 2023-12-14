<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import type { Sizes } from './types.ts'

export interface Props {
  size?: Sizes
  prefixIcon?: string
  suffixIcon?: string
}

const props = withDefaults(defineProps<Props>(), {
  size: 'medium',
})

const fontSizeClassMap = {
  small: 'text-xs',
  medium: 'text-sm',
  large: 'text-base',
  xl: 'text-xl',
}

const iconClassMap = {
  small: 'xs',
  medium: 'tiny',
  large: 'small',
  xl: 'base',
} as const
</script>

<template>
  <span
    class="dark:text-neutral-400 text-gray-100 inline-flex justify-start items-center gap-1"
    :class="fontSizeClassMap[props.size]"
    data-test-id="common-label"
  >
    <CommonIcon
      v-if="prefixIcon"
      :size="iconClassMap[props.size]"
      :name="prefixIcon"
    />

    <slot />

    <CommonIcon
      v-if="suffixIcon"
      :size="iconClassMap[props.size]"
      :name="suffixIcon"
    />
  </span>
</template>
