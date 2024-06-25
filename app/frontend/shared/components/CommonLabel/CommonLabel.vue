<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import type { Sizes } from './types.ts'

export interface Props {
  size?: Sizes
  iconColor?: string
  prefixIcon?: string
  suffixIcon?: string
  tag?: 'span' | 'p' | 'h2'
}

const props = withDefaults(defineProps<Props>(), {
  size: 'medium',
  tag: 'span',
})

const fontSizeClassMap = {
  xs: 'text-[10px] leading-[10px]',
  small: 'text-xs leading-snug',
  medium: 'text-sm leading-snug',
  large: 'text-base leading-snug',
  xl: 'text-xl leading-snug',
}

const iconClassMap = {
  xs: 'xs',
  small: 'xs',
  medium: 'tiny',
  large: 'small',
  xl: 'base',
} as const
</script>

<template>
  <component
    :is="tag"
    class="-:gap-1 -:text-gray-100 -:dark:text-neutral-400 -:inline-flex items-center justify-start"
    :class="fontSizeClassMap[props.size]"
    data-test-id="common-label"
  >
    <CommonIcon
      v-if="prefixIcon"
      class="shrink-0"
      :size="iconClassMap[props.size]"
      :name="prefixIcon"
      :class="iconColor"
      decorative
    />

    <slot />

    <CommonIcon
      v-if="suffixIcon"
      class="shrink-0"
      :size="iconClassMap[props.size]"
      :name="suffixIcon"
      :class="iconColor"
      decorative
    />
  </component>
</template>
