<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import type { Sizes } from './types.ts'

export interface Props {
  size?: Sizes
  iconColor?: string
  prefixIcon?: string
  suffixIcon?: string
}

const props = withDefaults(defineProps<Props>(), {
  size: 'medium',
})

const fontSizeClassMap = {
  small: 'text-xs leading-3',
  medium: 'text-sm leading-4',
  large: 'text-base leading-5',
  xl: 'text-xl leading-6',
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
    class="-:gap-1 -:text-gray-100 -:dark:text-neutral-400 inline-flex items-center justify-start"
    :class="fontSizeClassMap[props.size]"
    data-test-id="common-label"
  >
    <CommonIcon
      v-if="prefixIcon"
      :size="iconClassMap[props.size]"
      :name="prefixIcon"
      :class="iconColor"
      decorative
    />

    <slot />

    <CommonIcon
      v-if="suffixIcon"
      :size="iconClassMap[props.size]"
      :name="suffixIcon"
      :class="iconColor"
      decorative
    />
  </span>
</template>
