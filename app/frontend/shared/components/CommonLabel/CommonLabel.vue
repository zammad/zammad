<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import type { Sizes } from './types.ts'

export interface Props {
  size?: Sizes
  prefix?: string
  suffix?: string
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
    class="inline-flex justify-start items-center gap-1"
    :class="fontSizeClassMap[props.size]"
    data-test-id="common-label"
  >
    <CommonIcon v-if="prefix" :size="iconClassMap[props.size]" :name="prefix" />

    <slot />

    <CommonIcon v-if="suffix" :size="iconClassMap[props.size]" :name="suffix" />
  </span>
</template>
