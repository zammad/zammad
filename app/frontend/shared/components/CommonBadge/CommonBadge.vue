<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import { getBadgeClasses } from '#shared/initializer/initializeBadgeClasses.ts'

import type { BadgeSize, BadgeVariant } from './types.ts'

export interface Props {
  variant?: BadgeVariant
  size?: BadgeSize
  tag?: 'span' | 'div'
  rounded?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  variant: 'info',
  size: 'small',
  tag: 'span',
})

const sizeClasses = computed(() => {
  switch (props.size) {
    case 'dot':
      return 'text-[0px]'
    case 'large':
      return 'text-base'
    case 'medium':
      return 'text-sm'
    case 'xs':
      return 'text-[10px]'
    case 'circle':
    case 'small':
    default:
      return 'text-xs'
  }
})

const paddingClasses = computed(() => {
  switch (props.size) {
    case 'dot':
      return ['size-2', 'p-0']
    case 'circle':
      return ['size-6', 'p-0']
    case 'large':
      return ['px-4', 'py-2.5']
    case 'medium':
      return ['px-3', 'py-2']
    case 'xs':
      return ['px-1.5', 'py-0.5']
    case 'small':
    default:
      return ['px-2', 'py-1']
  }
})

const borderRadiusClass = computed(() => {
  if (props.rounded || props.size === 'dot' || props.size === 'circle') return 'rounded-full'

  switch (props.size) {
    case 'large':
      return 'rounded-xl'
    case 'medium':
      return 'rounded-lg'
    case 'small':
    default:
      return 'rounded-md'
  }
})

const classMap = getBadgeClasses()
</script>

<template>
  <component
    :is="tag"
    class="cursor-default"
    :class="[
      classMap.base,
      classMap[props.variant],
      ...paddingClasses,
      sizeClasses,
      borderRadiusClass,
    ]"
    data-test-id="common-badge"
  >
    <slot />
  </component>
</template>
